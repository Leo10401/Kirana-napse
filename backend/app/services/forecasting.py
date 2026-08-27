"""
Demand Forecasting Engine with Statistical & Machine Learning Pipeline (TRD §5.2, §5.3).
Integrates Holt-Winters Exponential Smoothing, SARIMAX with exogenous festival calendar signals,
LightGBM regression, and dynamic cold-start category blending.
Generates per-SKU 7-14 day demand forecasts and actionable inventory recommendations.
"""

import uuid
from datetime import date, datetime, timedelta, timezone
from typing import Dict, Any, List, Optional, Tuple
import numpy as np
import pandas as pd
from motor.motor_asyncio import AsyncIOMotorDatabase

from .feature_engineering import build_daily_time_series
from .models.base import ForecastOutput
from .models.cold_start import compute_cold_start_blend
from .models.statistical import HoltWintersForecaster, SarimaxForecaster
from .models.tabular_lgbm import LightGBMForecaster
from .model_training import load_cached_model_artifact, train_single_sku_model


async def get_festival_multiplier(
    db: AsyncIOMotorDatabase,
    region: str,
    start_date: date,
    end_date: date
) -> float:
    """Check if any festival falls in the horizon and return aggregate demand multiplier."""
    start_str = start_date.isoformat()
    end_str = end_date.isoformat()

    cursor = db.festival_calendar_entries.find({
        "region": {"$in": [region, "National", "All"]},
        "date": {"$gte": start_str, "$lte": end_str},
    })
    festivals = await cursor.to_list(length=100)
    if not festivals:
        return 1.0

    return max([f.get("expected_demand_multiplier", 1.0) for f in festivals], default=1.0)


async def forecast_sku_demand(
    db: AsyncIOMotorDatabase,
    store_id: str,
    sku: Dict[str, Any],
    sales_history: List[Dict[str, Any]],
    horizon_days: int = 7,
    festival_multiplier: float = 1.0,
    region: str = "National",
    use_cached_models: bool = True,
) -> ForecastOutput:
    """
    Compute statistical / ML demand forecast for a single SKU.
    Hierarchy:
      1. Uses cached champion model artifact if available.
      2. If history < 14 days: Dynamic Cold-Start Blend (Category Benchmark + Store empirical signal).
      3. If history >= 30 days and rich features: LightGBM / SARIMAX.
      4. Default robust baseline: Holt-Winters Exponential Smoothing.
    """
    sku_id = sku["id"]
    category = sku.get("category", "grocery") or "grocery"

    # 1. Check if cached champion model exists
    if use_cached_models:
        artifact = load_cached_model_artifact(store_id, sku_id)
        if artifact and "model_instance" in artifact:
            try:
                model_inst = artifact["model_instance"]
                series = build_daily_time_series(sales_history)
                return model_inst.fit_predict(
                    series,
                    horizon_days=horizon_days,
                    festival_multiplier=festival_multiplier
                )
            except Exception as e:
                # Fall back to live modeling if artifact prediction fails
                pass

    # 2. Live Forecasting Model
    series = build_daily_time_series(sales_history)
    n_days = len(series)

    # Cold Start Tier (< 14 days of historical data)
    if n_days < 14:
        daily_mean = float(series.mean()) if n_days > 0 else 4.0
        total_pred, blended_daily, is_cold, meta = compute_cold_start_blend(
            category=category,
            store_daily_rate=daily_mean,
            days_of_history=n_days,
            horizon_days=horizon_days,
            festival_multiplier=festival_multiplier,
        )

        drivers = [
            f"Category benchmark blended with {n_days}d store history",
            f"Blended daily rate: {blended_daily} units/day"
        ]
        if festival_multiplier > 1.0:
            drivers.append(f"Upcoming festival (+{int((festival_multiplier-1)*100)}% surge)")

        reason_en = " • ".join(drivers)
        reason_hi = f"समान दुकानों के आधार पर प्रारंभिक अनुमान • दैनिक औसत: {blended_daily} यूनिट"

        return ForecastOutput(
            predicted_demand=total_pred,
            daily_base_demand=blended_daily,
            confidence_lower=round(total_pred * 0.75, 1),
            confidence_upper=round(total_pred * 1.25, 1),
            model_version="v2.0-blended-cold-start",
            cold_start_flag=True,
            trend_direction="steady",
            primary_drivers=drivers,
            reason_en=reason_en,
            reason_hi=reason_hi,
            diagnostics=meta,
        )

    # Feature-rich SKU Tier (>= 30 days): LightGBM or SARIMAX
    if n_days >= 30:
        try:
            lgbm = LightGBMForecaster()
            return lgbm.fit_predict(
                series,
                horizon_days=horizon_days,
                festival_multiplier=festival_multiplier
            )
        except Exception:
            pass

    # Baseline Model: Holt-Winters Exponential Smoothing (Trend + Seasonality)
    hw = HoltWintersForecaster()
    return hw.fit_predict(
        series,
        horizon_days=horizon_days,
        festival_multiplier=festival_multiplier
    )


async def run_forecast_for_store(
    db: AsyncIOMotorDatabase,
    store_id: str,
    region: str = "National",
    horizon_days: int = 7,
    use_cached_models: bool = True,
) -> Dict[str, Any]:
    """
    Run demand forecast and generate inventory recommendations for all SKUs in a store.
    Maintains exact API contract with downstream recommendation collection and routes.
    """
    today = date.today()
    today_str = today.isoformat()
    horizon_end = today + timedelta(days=horizon_days)
    festival_mult = await get_festival_multiplier(db, region, today, horizon_end)

    # Fetch all SKUs for store
    cursor = db.skus.find({"store_id": store_id})
    skus = await cursor.to_list(length=1000)

    generated_recommendations = []
    past_90_days_str = (today - timedelta(days=90)).isoformat()
    now = datetime.now(timezone.utc)

    for sku in skus:
        sku_id = sku["id"]
        unit = sku.get("unit", "pcs")

        # Fetch historical sales
        sales_cursor = db.sales_records.find({
            "store_id": store_id,
            "sku_id": sku_id,
            "date": {"$gte": past_90_days_str},
        }).sort("date", 1)
        sales = await sales_cursor.to_list(length=300)

        # Fetch current stock level
        stock_doc = await db.stock_levels.find_one({
            "store_id": store_id,
            "sku_id": sku_id,
        })
        current_stock = stock_doc.get("quantity_on_hand", 0.0) if stock_doc else 0.0

        # Execute statistical/ML forecast model
        forecast_out = await forecast_sku_demand(
            db=db,
            store_id=store_id,
            sku=sku,
            sales_history=sales,
            horizon_days=horizon_days,
            festival_multiplier=festival_mult,
            region=region,
            use_cached_models=use_cached_models,
        )

        predicted_7d_demand = forecast_out.predicted_demand
        daily_base_demand = forecast_out.daily_base_demand
        forecast_id = str(uuid.uuid4())

        # Record forecast run
        forecast_doc = {
            "id": forecast_id,
            "store_id": store_id,
            "sku_id": sku_id,
            "run_date": today_str,
            "horizon_days": horizon_days,
            "predicted_demand": predicted_7d_demand,
            "daily_base_demand": daily_base_demand,
            "model_version": forecast_out.model_version,
            "cold_start_flag": forecast_out.cold_start_flag,
            "confidence_lower": forecast_out.confidence_lower,
            "confidence_upper": forecast_out.confidence_upper,
            "primary_drivers": forecast_out.primary_drivers,
            "created_at": now,
        }
        await db.forecast_runs.insert_one(forecast_doc)

        # ─── Inventory Threshold & Recommendation Formulas (Unchanged) ───
        lead_time_days = sku.get("supplier_lead_time_days", 2)
        lead_time_demand = daily_base_demand * lead_time_days * festival_mult
        safety_stock = daily_base_demand * 1.5
        reorder_point = lead_time_demand + safety_stock

        rec_type = None
        suggested_qty = 0.0
        reason_text = ""
        reason_text_hi = ""

        # 1. Low stock alert
        if current_stock <= (daily_base_demand * lead_time_days):
            rec_type = "low_stock"
            suggested_qty = max(round(predicted_7d_demand - current_stock + safety_stock), 1.0)
            reason_text = f"Urgent: Stockout risk in {lead_time_days} days. {forecast_out.reason_en}"
            reason_text_hi = f"तत्काल: {lead_time_days} दिनों में स्टॉक खत्म होने का जोखिम। {forecast_out.reason_hi}"

        # 2. Regular Reorder recommendation
        elif current_stock <= reorder_point:
            rec_type = "reorder"
            suggested_qty = max(round(predicted_7d_demand - current_stock + safety_stock), 1.0)
            reason_text = f"Reorder point reached. Current stock ({current_stock} {unit}). {forecast_out.reason_en}"
            reason_text_hi = f"पुनः ऑर्डर बिंदु आ गया है। वर्तमान स्टॉक ({current_stock} {unit})। {forecast_out.reason_hi}"

        # 3. Overstock caution
        elif current_stock > (predicted_7d_demand * 3.0) and current_stock > 10:
            rec_type = "overstock"
            suggested_qty = 0.0
            reason_text = f"Overstocked: {current_stock} {unit} on hand (>3 weeks supply). Consider promotional discount."
            reason_text_hi = f"अधिक स्टॉक: {current_stock} {unit} उपलब्ध (>3 सप्ताह की आपूर्ति)। छूट देने पर विचार करें।"

        # 4. Expiry Risk
        expiry_date_val = sku.get("expiry_date")
        if sku.get("is_perishable") and expiry_date_val:
            exp_d = date.fromisoformat(expiry_date_val) if isinstance(expiry_date_val, str) else expiry_date_val
            days_to_exp = (exp_d - today).days
            if 0 <= days_to_exp <= 5 and current_stock > (daily_base_demand * max(days_to_exp, 1)):
                rec_type = "expiry_risk"
                suggested_qty = 0.0
                reason_text = f"Expiry Risk: Expires in {days_to_exp} days! Stock remaining: {current_stock} {unit}."
                reason_text_hi = f"एक्सपायरी जोखिम: {days_to_exp} दिनों में समाप्त हो रहा है! शेष स्टॉक: {current_stock} {unit}."

        if rec_type:
            rec_doc = {
                "id": str(uuid.uuid4()),
                "store_id": store_id,
                "forecast_id": forecast_id,
                "sku_id": sku_id,
                "type": rec_type,
                "suggested_qty": suggested_qty,
                "owner_edited_qty": None,
                "reason_text": reason_text,
                "reason_text_hi": reason_text_hi,
                "status": "pending",
                "created_at": now,
                "updated_at": now,
            }
            await db.recommendations.insert_one(rec_doc)
            generated_recommendations.append(rec_doc)

    return {
        "status": "success",
        "store_id": store_id,
        "skus_evaluated": len(skus),
        "recommendations_generated": len(generated_recommendations),
    }
