"""
Feature Engineering for Kirana Demand Forecasting.
Extracts lags, rolling statistics, calendar signals, and festival indicators from raw SalesRecords.
"""

from typing import List, Dict, Any, Optional
from datetime import datetime, date, timedelta
import pandas as pd
import numpy as np


def build_daily_time_series(
    sales_records: List[Dict[str, Any]],
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
) -> pd.Series:
    """
    Transforms raw MongoDB sales records into a continuous daily time series,
    filling non-trading / zero-sale days with 0.0.
    """
    if not sales_records:
        if start_date and end_date:
            dates = pd.date_range(start=start_date, end=end_date, freq="D")
            return pd.Series(0.0, index=dates, name="quantity_sold")
        return pd.Series(dtype=float, name="quantity_sold")

    df = pd.DataFrame(sales_records)
    df["date"] = pd.to_datetime(df["date"])
    df["quantity_sold"] = df["quantity_sold"].astype(float)

    # Group by date in case multiple sales transactions occurred on same day
    daily = df.groupby("date")["quantity_sold"].sum()

    # Reindex to full continuous date range
    s_date = start_date if start_date else daily.index.min()
    e_date = end_date if end_date else daily.index.max()
    full_idx = pd.date_range(start=s_date, end=e_date, freq="D")

    series = daily.reindex(full_idx, fill_value=0.0)
    series.name = "quantity_sold"
    return series


def extract_tabular_features(
    series: pd.Series,
    festival_multipliers: Optional[Dict[str, float]] = None,
) -> pd.DataFrame:
    """
    Extracts tabular features from a continuous daily time-series.
    Features:
      - Lags: lag_1, lag_2, lag_3, lag_7, lag_14
      - Rolling: rolling_mean_7, rolling_std_7, rolling_mean_14, rolling_min_7, rolling_max_7
      - Calendar: dayofweek, is_weekend, day_of_month, is_payday_surge
      - Festival: festival_mult, is_festival
    """
    if len(series) == 0:
        return pd.DataFrame()

    df = pd.DataFrame(index=series.index)
    df["target"] = series.values

    # Lag features
    df["lag_1"] = series.shift(1)
    df["lag_2"] = series.shift(2)
    df["lag_3"] = series.shift(3)
    df["lag_7"] = series.shift(7)
    df["lag_14"] = series.shift(14)

    # Rolling window statistics (shifted by 1 to prevent data leakage)
    s_shifted = series.shift(1)
    df["rolling_mean_7"] = s_shifted.rolling(window=7, min_periods=1).mean()
    df["rolling_std_7"] = s_shifted.rolling(window=7, min_periods=1).std().fillna(0.0)
    df["rolling_mean_14"] = s_shifted.rolling(window=14, min_periods=1).mean()
    df["rolling_min_7"] = s_shifted.rolling(window=7, min_periods=1).min()
    df["rolling_max_7"] = s_shifted.rolling(window=7, min_periods=1).max()

    # Calendar features
    df["dayofweek"] = df.index.dayofweek
    df["is_weekend"] = (df.index.dayofweek >= 5).astype(int)
    df["day_of_month"] = df.index.day
    # Payday surge: 1st to 5th and 28th to end of month
    df["is_payday_surge"] = ((df.index.day <= 5) | (df.index.day >= 28)).astype(int)

    # Festival multiplier feature
    fest_dict = festival_multipliers or {}
    df["festival_mult"] = [fest_dict.get(d.strftime("%Y-%m-%d"), 1.0) for d in df.index]
    df["is_festival"] = (df["festival_mult"] > 1.0).astype(int)

    return df.dropna()
