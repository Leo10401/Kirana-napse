"""
Statistical time-series forecasting models using statsmodels.
Includes Holt-Winters Exponential Smoothing (Baseline) and SARIMAX with exogenous regressors.
"""

from typing import Dict, Any, Optional, List
import numpy as np
import pandas as pd
import warnings

from .base import BaseForecaster, ForecastOutput

# Suppress statsmodels convergence warnings in high-throughput batch loops
warnings.filterwarnings("ignore")


class HoltWintersForecaster(BaseForecaster):
    """
    Holt-Winters Exponential Smoothing forecaster.
    Handles level, trend, and optional weekly seasonality for sparse retail series.
    """

    def __init__(self, seasonal_periods: int = 7):
        self.seasonal_periods = seasonal_periods

    def fit_predict(
        self,
        series: pd.Series,
        horizon_days: int = 7,
        festival_multiplier: float = 1.0,
        **kwargs
    ) -> ForecastOutput:
        from statsmodels.tsa.holtwinters import ExponentialSmoothing

        n_obs = len(series)
        series_clean = series.astype(float).clip(lower=0.0)

        # Fallback for ultra-short series (< 7 observations)
        if n_obs < 7:
            daily_mean = float(series_clean.mean()) if n_obs > 0 else 4.0
            predicted_demand = daily_mean * horizon_days * festival_multiplier
            return ForecastOutput(
                predicted_demand=predicted_demand,
                daily_base_demand=daily_mean,
                confidence_lower=predicted_demand * 0.8,
                confidence_upper=predicted_demand * 1.2,
                model_version="v2.0-holt-winters-cold-fallback",
                cold_start_flag=True,
                trend_direction="steady",
                primary_drivers=["Sparse history baseline"],
                reason_en=f"Recent daily avg: {round(daily_mean, 1)} units/day",
                reason_hi=f"हालिया दैनिक औसत: {round(daily_mean, 1)} यूनिट/दिन",
                diagnostics={"model": "fallback_mean", "n_obs": n_obs}
            )

        # Select Holt-Winters configuration based on history length
        trend_direction = "steady"
        try:
            if n_obs >= 14:
                # Full Holt-Winters: additive trend + additive weekly seasonality
                model = ExponentialSmoothing(
                    series_clean,
                    trend="add",
                    seasonal="add" if (series_clean > 0).sum() >= 10 else None,
                    seasonal_periods=self.seasonal_periods if (series_clean > 0).sum() >= 10 else None,
                    initialization_method="estimated"
                )
                fit_res = model.fit(damping_trend=0.9 if n_obs < 28 else None)
            else:
                # 7 - 13 observations: Trend only (no seasonal cycle yet)
                model = ExponentialSmoothing(
                    series_clean,
                    trend="add",
                    seasonal=None,
                    initialization_method="estimated"
                )
                fit_res = model.fit(damping_trend=0.85)

            forecast_values = fit_res.forecast(horizon_days)
            forecast_values = np.clip(forecast_values, a_min=0.0, a_max=None)
            base_predicted = float(forecast_values.sum())
            daily_base = float(forecast_values.mean())

            # Evaluate trend direction from model slope/level
            if hasattr(fit_res, "slope") and fit_res.slope is not None:
                slope_val = float(fit_res.slope[-1]) if hasattr(fit_res.slope, "__len__") else float(fit_res.slope)
                if slope_val > 0.05:
                    trend_direction = "upward"
                elif slope_val < -0.05:
                    trend_direction = "downward"

            # Compute empirical residual standard error for confidence intervals
            residuals = series_clean - fit_res.fittedvalues
            rmse = float(np.sqrt(np.mean(residuals ** 2))) if len(residuals) > 0 else (daily_base * 0.2)
            margin = float(1.645 * rmse * np.sqrt(horizon_days))  # 90% confidence interval

        except Exception as e:
            # Robust fallback to EWMA / rolling mean if non-convergent
            daily_base = float(series_clean.iloc[-7:].mean()) if n_obs >= 7 else float(series_clean.mean())
            base_predicted = daily_base * horizon_days
            margin = base_predicted * 0.2
            trend_direction = "steady"
            fit_res = None

        # Layer festival multiplier onto base forecast
        final_predicted = base_predicted * festival_multiplier
        conf_lower = max(0.0, final_predicted - (margin * festival_multiplier))
        conf_upper = final_predicted + (margin * festival_multiplier)

        # Build explainability drivers
        drivers = [f"Recent base rate: {round(daily_base, 1)} units/day"]
        if trend_direction == "upward":
            drivers.append("Sales trending upward over past week")
        elif trend_direction == "downward":
            drivers.append("Sales trending downward over past week")

        if festival_multiplier > 1.0:
            surge_pct = int((festival_multiplier - 1.0) * 100)
            drivers.append(f"Upcoming festival (+{surge_pct}% demand surge)")

        reason_en = " • ".join(drivers)
        reason_hi = f"दैनिक औसत: {round(daily_base, 1)} यूनिट"
        if festival_multiplier > 1.0:
            reason_hi += f" • आगामी त्योहार पर मांग वृद्धि"

        return ForecastOutput(
            predicted_demand=final_predicted,
            daily_base_demand=daily_base,
            confidence_lower=conf_lower,
            confidence_upper=conf_upper,
            model_version="v2.0-holt-winters",
            cold_start_flag=False,
            trend_direction=trend_direction,
            primary_drivers=drivers,
            reason_en=reason_en,
            reason_hi=reason_hi,
            diagnostics={
                "model": "Holt-Winters",
                "n_obs": n_obs,
                "festival_multiplier": festival_multiplier,
            }
        )


class SarimaxForecaster(BaseForecaster):
    """
    SARIMAX forecaster for SKUs with >= 30 days of sales.
    Supports exogenous festival and calendar surge features.
    """

    def __init__(self, order=(1, 0, 1), seasonal_order=(1, 0, 0, 7)):
        self.order = order
        self.seasonal_order = seasonal_order

    def fit_predict(
        self,
        series: pd.Series,
        horizon_days: int = 7,
        exog_train: Optional[pd.DataFrame] = None,
        exog_future: Optional[pd.DataFrame] = None,
        festival_multiplier: float = 1.0,
        **kwargs
    ) -> ForecastOutput:
        from statsmodels.tsa.statespace.sarimax import SARIMAX

        series_clean = series.astype(float).clip(lower=0.0)
        n_obs = len(series_clean)

        if n_obs < 30:
            # Fall back to Holt-Winters if insufficient history
            hw = HoltWintersForecaster()
            return hw.fit_predict(series_clean, horizon_days=horizon_days, festival_multiplier=festival_multiplier)

        try:
            model = SARIMAX(
                series_clean,
                exog=exog_train,
                order=self.order,
                seasonal_order=self.seasonal_order if n_obs >= 42 else None,
                enforce_stationarity=False,
                enforce_invertibility=False
            )
            fit_res = model.fit(disp=False, maxiter=50)

            forecast_res = fit_res.get_forecast(steps=horizon_days, exog=exog_future)
            predicted_series = forecast_res.predicted_mean.clip(lower=0.0)
            conf_int = forecast_res.conf_int(alpha=0.1)  # 90% confidence bounds

            base_predicted = float(predicted_series.sum())
            daily_base = float(predicted_series.mean())

            conf_lower = float(conf_int.iloc[:, 0].clip(lower=0.0).sum())
            conf_upper = float(conf_int.iloc[:, 1].clip(lower=0.0).sum())

            # Check if festival was explicitly in exog or layered
            final_predicted = base_predicted if exog_train is not None else (base_predicted * festival_multiplier)
            if exog_train is None:
                conf_lower *= festival_multiplier
                conf_upper *= festival_multiplier

            drivers = [f"SARIMAX time-series modeled (AIC: {round(fit_res.aic, 1)})"]
            if festival_multiplier > 1.0:
                drivers.append(f"Festival surge factored (+{int((festival_multiplier-1)*100)}%)")

            return ForecastOutput(
                predicted_demand=final_predicted,
                daily_base_demand=daily_base,
                confidence_lower=conf_lower,
                confidence_upper=conf_upper,
                model_version="v2.0-sarimax",
                cold_start_flag=False,
                trend_direction="steady",
                primary_drivers=drivers,
                reason_en=" • ".join(drivers),
                reason_hi=f"दैनिक मांग अनुमान: {round(daily_base, 1)} यूनिट/दिन",
                diagnostics={
                    "model": "SARIMAX",
                    "aic": round(fit_res.aic, 2),
                    "n_obs": n_obs,
                }
            )

        except Exception as e:
            # Safe fallback to Holt-Winters
            hw = HoltWintersForecaster()
            return hw.fit_predict(series_clean, horizon_days=horizon_days, festival_multiplier=festival_multiplier)
