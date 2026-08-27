"""
Backtesting & Model Validation Harness (PRD §5.2).
Evaluates models using walk-forward holdout validation and benchmarks accuracy (MAPE / WAPE / RMSE)
against the PRD target (MAPE < 25% on high-volume SKUs).
"""

from typing import Dict, Any, List, Optional, Tuple
from datetime import date, timedelta
import numpy as np
import pandas as pd
from motor.motor_asyncio import AsyncIOMotorDatabase

from .feature_engineering import build_daily_time_series
from .models.cold_start import compute_cold_start_blend
from .models.statistical import HoltWintersForecaster, SarimaxForecaster
from .models.tabular_lgbm import LightGBMForecaster


def compute_metrics(actuals: np.ndarray, predictions: np.ndarray) -> Dict[str, float]:
    """Compute MAPE, WAPE, and RMSE between actual and predicted demand."""
    act = np.array(actuals, dtype=float)
    pred = np.array(predictions, dtype=float)

    # Avoid zero division in MAPE by using max(actual, 1.0)
    denominator = np.maximum(act, 1.0)
    mape = float(np.mean(np.abs(act - pred) / denominator) * 100.0)

    # Weighted Absolute Percentage Error (WAPE)
    total_act = float(np.sum(act))
    wape = float(np.sum(np.abs(act - pred)) / max(total_act, 1.0) * 100.0)

    # Root Mean Squared Error
    rmse = float(np.sqrt(np.mean((act - pred) ** 2)))

    return {
        "mape": round(mape, 2),
        "wape": round(wape, 2),
        "rmse": round(rmse, 2),
    }


async def evaluate_sku_backtest(
    sales_records: List[Dict[str, Any]],
    category: str,
    holdout_days: int = 7,
    festival_multiplier: float = 1.0,
) -> Dict[str, Any]:
    """
    Simulate walk-forward backtest on a single SKU's sales history.
    Splits series into train (< cutoff) and test (holdout_days).
    Evaluates Holt-Winters, SARIMAX, LightGBM, and baseline Moving Average.
    """
    full_series = build_daily_time_series(sales_records)
    n_days = len(full_series)

    if n_days < (holdout_days + 4):
        # Extremely short series
        return {
            "status": "insufficient_data",
            "days_of_history": n_days,
            "category": category,
            "metrics": {},
        }

    train_series = full_series.iloc[:-holdout_days]
    test_series = full_series.iloc[-holdout_days:]
    actual_holdout = float(test_series.sum())

    model_evaluations: Dict[str, Dict[str, Any]] = {}

    # 1. Moving Average Baseline
    ma_daily = float(train_series.mean()) if len(train_series) > 0 else 4.0
    ma_pred = ma_daily * holdout_days * festival_multiplier
    model_evaluations["moving_average"] = {
        "predicted": round(ma_pred, 1),
        "metrics": compute_metrics(np.array([actual_holdout]), np.array([ma_pred])),
    }

    # 2. Holt-Winters Exponential Smoothing
    hw = HoltWintersForecaster()
    hw_out = hw.fit_predict(train_series, horizon_days=holdout_days, festival_multiplier=festival_multiplier)
    model_evaluations["holt_winters"] = {
        "predicted": round(hw_out.predicted_demand, 1),
        "metrics": compute_metrics(np.array([actual_holdout]), np.array([hw_out.predicted_demand])),
    }

    # 3. SARIMAX (if >= 30 days of train history)
    if len(train_series) >= 30:
        sar = SarimaxForecaster()
        sar_out = sar.fit_predict(train_series, horizon_days=holdout_days, festival_multiplier=festival_multiplier)
        model_evaluations["sarimax"] = {
            "predicted": round(sar_out.predicted_demand, 1),
            "metrics": compute_metrics(np.array([actual_holdout]), np.array([sar_out.predicted_demand])),
        }

    # 4. LightGBM (if >= 28 days of train history)
    if len(train_series) >= 28:
        lgbm = LightGBMForecaster()
        lgbm_out = lgbm.fit_predict(train_series, horizon_days=holdout_days, festival_multiplier=festival_multiplier)
        model_evaluations["lightgbm"] = {
            "predicted": round(lgbm_out.predicted_demand, 1),
            "metrics": compute_metrics(np.array([actual_holdout]), np.array([lgbm_out.predicted_demand])),
        }

    # Identify champion model for this SKU
    best_model_name = min(
        model_evaluations.keys(),
        key=lambda k: model_evaluations[k]["metrics"]["mape"]
    )

    return {
        "status": "success",
        "category": category,
        "days_of_history": n_days,
        "actual_demand": round(actual_holdout, 1),
        "champion_model": best_model_name,
        "champion_mape": model_evaluations[best_model_name]["metrics"]["mape"],
        "evaluations": model_evaluations,
    }


async def run_store_backtest(
    db: AsyncIOMotorDatabase,
    store_id: str,
    holdout_days: int = 7,
) -> Dict[str, Any]:
    """
    Run backtest validation across all SKUs in a store.
    Produces category-level aggregated MAPE/WAPE report against PRD targets (<25%).
    """
    skus_cursor = db.skus.find({"store_id": store_id})
    skus = await skus_cursor.to_list(length=500)

    results = []
    category_mapes: Dict[str, List[float]] = {}
    champion_counts: Dict[str, int] = {}

    for sku in skus:
        sku_id = sku["id"]
        category = sku.get("category", "grocery") or "grocery"

        sales_cursor = db.sales_records.find({
            "store_id": store_id,
            "sku_id": sku_id,
        }).sort("date", 1)
        sales = await sales_cursor.to_list(length=1000)

        eval_res = await evaluate_sku_backtest(sales, category=category, holdout_days=holdout_days)
        eval_res["sku_id"] = sku_id
        eval_res["sku_name"] = sku["name"]

        results.append(eval_res)

        if eval_res["status"] == "success":
            champ = eval_res["champion_model"]
            champion_counts[champ] = champion_counts.get(champ, 0) + 1

            cat_clean = category.strip().lower()
            if cat_clean not in category_mapes:
                category_mapes[cat_clean] = []
            category_mapes[cat_clean].append(eval_res["champion_mape"])

    # Aggregate by category
    category_summary = {}
    overall_mapes = []

    for cat, mapes in category_mapes.items():
        avg_mape = float(np.mean(mapes)) if mapes else 0.0
        category_summary[cat] = {
            "skus_count": len(mapes),
            "average_mape": round(avg_mape, 2),
            "target_met_lt_25pct": avg_mape <= 25.0,
        }
        overall_mapes.extend(mapes)

    overall_avg_mape = float(np.mean(overall_mapes)) if overall_mapes else 0.0

    return {
        "store_id": store_id,
        "holdout_days": holdout_days,
        "total_skus_evaluated": len(results),
        "overall_average_mape": round(overall_avg_mape, 2),
        "prd_target_achieved": overall_avg_mape <= 25.0,
        "champion_model_distribution": champion_counts,
        "category_performance": category_summary,
        "sku_details": results,
    }
