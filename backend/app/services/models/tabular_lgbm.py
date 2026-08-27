"""
LightGBM Tabular Forecaster for Feature-Rich SKUs.
Trains a gradient-boosted tree regressor on lag, rolling, calendar, and festival features.
Used when historical backtesting confirms higher accuracy than baseline statistical models.
"""

from typing import Dict, Any, List, Optional
import numpy as np
import pandas as pd
from datetime import date, timedelta

from .base import BaseForecaster, ForecastOutput
from ..feature_engineering import extract_tabular_features


class LightGBMForecaster(BaseForecaster):
    """
    LightGBM Gradient Boosted Trees Forecaster for retail SKU demand.
    """

    def __init__(self, n_estimators: int = 40, max_depth: int = 4, learning_rate: float = 0.08):
        self.n_estimators = n_estimators
        self.max_depth = max_depth
        self.learning_rate = learning_rate
        self.model = None
        self.feature_names: List[str] = []

    def fit_predict(
        self,
        series: pd.Series,
        horizon_days: int = 7,
        festival_multipliers: Optional[Dict[str, float]] = None,
        festival_multiplier: float = 1.0,
        **kwargs
    ) -> ForecastOutput:
        import lightgbm as lgb
        from .statistical import HoltWintersForecaster

        # Need sufficient observations to build lags + train trees
        if len(series) < 28:
            # Fall back to statistical Holt-Winters
            hw = HoltWintersForecaster()
            return hw.fit_predict(series, horizon_days=horizon_days, festival_multiplier=festival_multiplier)

        df_feat = extract_tabular_features(series, festival_multipliers=festival_multipliers)
        if len(df_feat) < 14:
            hw = HoltWintersForecaster()
            return hw.fit_predict(series, horizon_days=horizon_days, festival_multiplier=festival_multiplier)

        X = df_feat.drop(columns=["target"])
        y = df_feat["target"]
        self.feature_names = list(X.columns)

        # Train lightweight model
        self.model = lgb.LGBMRegressor(
            n_estimators=self.n_estimators,
            max_depth=self.max_depth,
            learning_rate=self.learning_rate,
            num_leaves=min(15, 2 ** self.max_depth),
            min_child_samples=max(3, len(X) // 10),
            subsample=0.85,
            colsample_bytree=0.85,
            random_state=42,
            verbose=-1
        )
        self.model.fit(X, y)

        # Multi-step recursive forecasting
        history_values = list(series.values)
        predictions = []
        last_date = series.index[-1]
        fest_dict = festival_multipliers or {}

        for step in range(1, horizon_days + 1):
            next_date = last_date + timedelta(days=step)
            # Construct row
            row = {}
            for lag in [1, 2, 3, 7, 14]:
                idx = len(history_values) - lag
                row[f"lag_{lag}"] = history_values[idx] if idx >= 0 else history_values[0]

            s_recent = history_values[-14:]
            row["rolling_mean_7"] = np.mean(history_values[-7:]) if len(history_values) >= 7 else np.mean(history_values)
            row["rolling_std_7"] = np.std(history_values[-7:]) if len(history_values) >= 7 else 0.0
            row["rolling_mean_14"] = np.mean(s_recent)
            row["rolling_min_7"] = np.min(history_values[-7:]) if len(history_values) >= 7 else np.min(history_values)
            row["rolling_max_7"] = np.max(history_values[-7:]) if len(history_values) >= 7 else np.max(history_values)

            row["dayofweek"] = next_date.weekday()
            row["is_weekend"] = 1 if next_date.weekday() >= 5 else 0
            row["day_of_month"] = next_date.day
            row["is_payday_surge"] = 1 if (next_date.day <= 5 or next_date.day >= 28) else 0

            date_str = next_date.strftime("%Y-%m-%d")
            row["festival_mult"] = fest_dict.get(date_str, festival_multiplier)
            row["is_festival"] = 1 if row["festival_mult"] > 1.0 else 0

            df_step = pd.DataFrame([row])[self.feature_names]
            step_pred = float(np.clip(self.model.predict(df_step)[0], a_min=0.0, a_max=None))
            predictions.append(step_pred)
            history_values.append(step_pred)

        total_predicted = float(sum(predictions))
        daily_base = float(np.mean(predictions))

        # Explainability via Feature Importance
        importances = self.model.feature_importances_
        feat_imp = sorted(zip(self.feature_names, importances), key=lambda x: x[1], reverse=True)
        top_features = [f[0] for f in feat_imp[:3]]

        drivers = [f"ML Model prediction (Recent 7d avg: {round(daily_base, 1)} units/day)"]
        if "is_weekend" in top_features or "dayofweek" in top_features:
            drivers.append("Strong weekend sales pattern detected")
        if "is_festival" in top_features or festival_multiplier > 1.0:
            drivers.append(f"Upcoming festival surge factored (+{int((festival_multiplier-1)*100)}%)")
        if "lag_1" in top_features or "rolling_mean_7" in top_features:
            drivers.append("Recent momentum driving demand")

        reason_en = " • ".join(drivers)
        reason_hi = f"मशीन लर्निंग मॉडल: हालिया दैनिक औसत {round(daily_base, 1)} यूनिट/दिन"

        return ForecastOutput(
            predicted_demand=total_predicted,
            daily_base_demand=daily_base,
            confidence_lower=max(0.0, total_predicted * 0.82),
            confidence_upper=total_predicted * 1.18,
            model_version="v2.0-lightgbm",
            cold_start_flag=False,
            trend_direction="steady",
            primary_drivers=drivers,
            reason_en=reason_en,
            reason_hi=reason_hi,
            diagnostics={
                "model": "LightGBM",
                "n_obs": len(series),
                "top_features": top_features,
            }
        )
