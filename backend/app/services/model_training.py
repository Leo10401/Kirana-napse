"""
Model Training & Artifact Persistence Pipeline (PRD §5.2).
Nightly batch job that trains, evaluates, and persists champion forecasting models per SKU.
"""

import os
import uuid
import joblib
from datetime import datetime, date, timezone
from typing import Dict, Any, List, Optional
import numpy as np
import pandas as pd
from motor.motor_asyncio import AsyncIOMotorDatabase

from .feature_engineering import build_daily_time_series
from .models.base import ForecastOutput
from .models.cold_start import compute_cold_start_blend
from .models.statistical import HoltWintersForecaster, SarimaxForecaster
from .models.tabular_lgbm import LightGBMForecaster
from .backtesting import evaluate_sku_backtest

# Artifact cache directory
MODEL_CACHE_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "models_cache")
os.makedirs(MODEL_CACHE_DIR, exist_ok=True)


def get_artifact_path(store_id: str, sku_id: str) -> str:
    """Generate filepath for persisted model artifact."""
    clean_store = "".join([c if c.isalnum() else "_" for c in store_id])
    clean_sku = "".join([c if c.isalnum() else "_" for c in sku_id])
    return os.path.join(MODEL_CACHE_DIR, f"{clean_store}_{clean_sku}.joblib")


async def train_single_sku_model(
    db: AsyncIOMotorDatabase,
    store_id: str,
    sku: Dict[str, Any],
    festival_multiplier: float = 1.0,
) -> Dict[str, Any]:
    """
    Train and select champion model for a single SKU.
    1. Fetches sales history.
    2. Runs backtest validation across candidate models.
    3. Selects winning model and fits on full history.
    4. Persists artifact and records training metadata.
    """
    sku_id = sku["id"]
    category = sku.get("category", "grocery") or "grocery"

    sales_cursor = db.sales_records.find({
        "store_id": store_id,
        "sku_id": sku_id,
    }).sort("date", 1)
    sales = await sales_cursor.to_list(length=1000)

    series = build_daily_time_series(sales)
    n_days = len(series)

    # 1. Cold Start Tier (< 14 days of history)
    if n_days < 14:
        daily_mean = float(series.mean()) if n_days > 0 else 4.0
        total_pred, blended_daily, is_cold, cold_meta = compute_cold_start_blend(
            category=category,
            store_daily_rate=daily_mean,
            days_of_history=n_days,
            horizon_days=7,
            festival_multiplier=festival_multiplier,
        )

        artifact_payload = {
            "store_id": store_id,
            "sku_id": sku_id,
            "sku_name": sku.get("name"),
            "category": category,
            "model_type": "cold_start_blend",
            "model_version": "v2.0-blended-cold-start",
            "trained_at": datetime.now(timezone.utc).isoformat(),
            "n_obs": n_days,
            "in_sample_mape": None,
            "daily_base_demand": blended_daily,
            "parameters": cold_meta,
        }
        joblib.dump(artifact_payload, get_artifact_path(store_id, sku_id))
        return artifact_payload

    # 2. Backtest Candidate Selection (>= 14 days of history)
    backtest_res = await evaluate_sku_backtest(
        sales, category=category, holdout_days=7, festival_multiplier=festival_multiplier
    )

    champion_type = backtest_res.get("champion_model", "holt_winters")
    champion_mape = backtest_res.get("champion_mape", 15.0)

    # 3. Fit Champion Model on Full History
    champion_model_obj = None
    model_version = f"v2.0-{champion_type}"

    if champion_type == "lightgbm" and n_days >= 28:
        forecaster = LightGBMForecaster()
        forecaster.fit_predict(series, horizon_days=7, festival_multiplier=festival_multiplier)
        champion_model_obj = forecaster
    elif champion_type == "sarimax" and n_days >= 30:
        forecaster = SarimaxForecaster()
        forecaster.fit_predict(series, horizon_days=7, festival_multiplier=festival_multiplier)
        champion_model_obj = forecaster
    else:
        # Default: Holt-Winters Exponential Smoothing
        forecaster = HoltWintersForecaster()
        forecaster.fit_predict(series, horizon_days=7, festival_multiplier=festival_multiplier)
        champion_model_obj = forecaster
        champion_type = "holt_winters"

    artifact_payload = {
        "store_id": store_id,
        "sku_id": sku_id,
        "sku_name": sku.get("name"),
        "category": category,
        "model_type": champion_type,
        "model_version": model_version,
        "model_instance": champion_model_obj,
        "trained_at": datetime.now(timezone.utc).isoformat(),
        "n_obs": n_days,
        "in_sample_mape": champion_mape,
        "evaluations": backtest_res.get("evaluations", {}),
    }

    # Persist artifact
    joblib.dump(artifact_payload, get_artifact_path(store_id, sku_id))

    # Log training run in MongoDB
    log_doc = {
        "id": str(uuid.uuid4()),
        "store_id": store_id,
        "sku_id": sku_id,
        "model_type": champion_type,
        "model_version": model_version,
        "validation_mape": champion_mape,
        "n_obs": n_days,
        "trained_at": datetime.now(timezone.utc),
    }
    await db.model_training_logs.insert_one(log_doc)

    return artifact_payload


async def train_store_models(
    db: AsyncIOMotorDatabase,
    store_id: str,
    festival_multiplier: float = 1.0,
) -> Dict[str, Any]:
    """
    Nightly training batch runner for all SKUs in a store.
    """
    cursor = db.skus.find({"store_id": store_id})
    skus = await cursor.to_list(length=1000)

    trained_count = 0
    model_type_counts: Dict[str, int] = {}

    for sku in skus:
        try:
            res = await train_single_sku_model(db, store_id, sku, festival_multiplier=festival_multiplier)
            m_type = res["model_type"]
            model_type_counts[m_type] = model_type_counts.get(m_type, 0) + 1
            trained_count += 1
        except Exception as e:
            print(f"[WARN] Training failed for SKU {sku.get('id')}: {e}")

    return {
        "status": "success",
        "store_id": store_id,
        "total_skus": len(skus),
        "trained_count": trained_count,
        "model_distribution": model_type_counts,
        "completed_at": datetime.now(timezone.utc).isoformat(),
    }


def load_cached_model_artifact(store_id: str, sku_id: str) -> Optional[Dict[str, Any]]:
    """Load persisted model artifact from disk if available."""
    path = get_artifact_path(store_id, sku_id)
    if os.path.exists(path):
        try:
            return joblib.load(path)
        except Exception:
            return None
    return None
