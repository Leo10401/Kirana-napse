"""
Unit and Integration tests for Kirana-Napse Statistical & ML Demand Forecasting Pipeline.
"""

import os
import unittest
import numpy as np
import pandas as pd
from datetime import date, timedelta

from app.services.models.base import ForecastOutput
from app.services.models.cold_start import compute_cold_start_blend, get_category_benchmark
from app.services.models.statistical import HoltWintersForecaster, SarimaxForecaster
from app.services.models.tabular_lgbm import LightGBMForecaster
from app.services.feature_engineering import build_daily_time_series, extract_tabular_features
from app.services.backtesting import compute_metrics
from app.services.model_training import get_artifact_path, load_cached_model_artifact
import joblib


class TestForecastingPipeline(unittest.TestCase):

    def setUp(self):
        np.random.seed(42)
        # Generate synthetic 45-day sales time series with weekly seasonality
        dates = pd.date_range(start="2026-07-01", periods=45, freq="D")
        base = 10.0
        weekly_cycle = np.array([0.8, 0.9, 1.0, 1.1, 1.3, 1.5, 0.7] * 7)[:45]
        noise = np.random.normal(0, 1.0, 45)
        sales = np.clip(base * weekly_cycle + noise, a_min=1.0, a_max=None)
        self.series = pd.Series(sales, index=dates, name="quantity_sold")

    def test_category_benchmarks_lookup(self):
        self.assertEqual(get_category_benchmark("dairy"), 10.0)
        self.assertEqual(get_category_benchmark("grocery"), 5.0)
        self.assertEqual(get_category_benchmark("snacks"), 8.0)
        self.assertEqual(get_category_benchmark("unknown_cat"), 4.0)

    def test_cold_start_blending(self):
        # 0 days of history -> 100% category benchmark
        pred_0, blended_0, is_cold_0, meta_0 = compute_cold_start_blend(
            category="dairy",
            store_daily_rate=20.0,
            days_of_history=0,
            horizon_days=7,
        )
        self.assertEqual(blended_0, 10.0)
        self.assertEqual(pred_0, 70.0)
        self.assertTrue(is_cold_0)

        # 30 days of history -> 50% benchmark (10.0) + 50% store (20.0) = 15.0
        pred_30, blended_30, is_cold_30, meta_30 = compute_cold_start_blend(
            category="dairy",
            store_daily_rate=20.0,
            days_of_history=30,
            horizon_days=7,
        )
        self.assertEqual(blended_30, 15.0)
        self.assertEqual(pred_30, 105.0)
        self.assertFalse(is_cold_30)

        # 60+ days of history -> 100% store empirical signal (20.0)
        pred_60, blended_60, is_cold_60, meta_60 = compute_cold_start_blend(
            category="dairy",
            store_daily_rate=20.0,
            days_of_history=60,
            horizon_days=7,
        )
        self.assertEqual(blended_60, 20.0)
        self.assertEqual(pred_60, 140.0)

    def test_holt_winters_forecaster(self):
        hw = HoltWintersForecaster()
        out: ForecastOutput = hw.fit_predict(self.series, horizon_days=7, festival_multiplier=1.2)

        self.assertIsInstance(out, ForecastOutput)
        self.assertGreater(out.predicted_demand, 0.0)
        self.assertGreater(out.daily_base_demand, 0.0)
        self.assertLess(out.confidence_lower, out.predicted_demand)
        self.assertGreater(out.confidence_upper, out.predicted_demand)
        self.assertEqual(out.model_version, "v2.0-holt-winters")
        self.assertIn("festival", out.reason_en.lower())

    def test_sarimax_forecaster(self):
        sar = SarimaxForecaster()
        out: ForecastOutput = sar.fit_predict(self.series, horizon_days=7, festival_multiplier=1.0)

        self.assertIsInstance(out, ForecastOutput)
        self.assertGreater(out.predicted_demand, 0.0)
        self.assertEqual(out.model_version, "v2.0-sarimax")
        self.assertFalse(out.cold_start_flag)

    def test_feature_engineering_tabular(self):
        df_feat = extract_tabular_features(self.series, festival_multipliers={"2026-07-15": 1.5})
        self.assertIn("lag_1", df_feat.columns)
        self.assertIn("lag_7", df_feat.columns)
        self.assertIn("rolling_mean_7", df_feat.columns)
        self.assertIn("is_weekend", df_feat.columns)
        self.assertIn("is_payday_surge", df_feat.columns)
        self.assertIn("festival_mult", df_feat.columns)

    def test_lightgbm_forecaster(self):
        lgbm = LightGBMForecaster(n_estimators=25)
        out: ForecastOutput = lgbm.fit_predict(self.series, horizon_days=7, festival_multiplier=1.1)

        self.assertIsInstance(out, ForecastOutput)
        self.assertGreater(out.predicted_demand, 0.0)
        self.assertEqual(out.model_version, "v2.0-lightgbm")
        self.assertTrue(len(out.primary_drivers) > 0)
        self.assertIn("top_features", out.diagnostics)

    def test_metrics_computation(self):
        actuals = np.array([10.0, 20.0, 30.0])
        predictions = np.array([11.0, 18.0, 33.0])
        metrics = compute_metrics(actuals, predictions)

        self.assertIn("mape", metrics)
        self.assertIn("wape", metrics)
        self.assertIn("rmse", metrics)
        self.assertLess(metrics["mape"], 20.0)  # Low error


if __name__ == "__main__":
    unittest.main()
