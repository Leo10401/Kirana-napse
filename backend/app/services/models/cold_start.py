"""
Dynamic Cold-Start Blending for Kirana Demand Forecasting.
Blends Category Benchmark priors with empirical store sales signals,
shifting weight smoothly from 100% benchmark toward 100% store model as history grows.
"""

from typing import Tuple, Dict, Any, Optional
import numpy as np
import pandas as pd

CATEGORY_BENCHMARKS: Dict[str, float] = {
    "dairy": 10.0,
    "grocery": 5.0,
    "snacks": 8.0,
    "beverages": 6.0,
    "personal care": 2.0,
}
DEFAULT_CATEGORY_BENCHMARK = 4.0

# 60 days (~8.5 weeks) to reach 100% store-specific weight
FULL_HISTORY_THRESHOLD_DAYS = 60


def get_category_benchmark(category: Optional[str]) -> float:
    """Lookup benchmark daily sales rate for a product category."""
    if not category:
        return DEFAULT_CATEGORY_BENCHMARK
    return CATEGORY_BENCHMARKS.get(category.strip().lower(), DEFAULT_CATEGORY_BENCHMARK)


def compute_cold_start_blend(
    category: Optional[str],
    store_daily_rate: float,
    days_of_history: int,
    horizon_days: int = 7,
    festival_multiplier: float = 1.0,
    full_history_threshold: int = FULL_HISTORY_THRESHOLD_DAYS,
) -> Tuple[float, float, bool, Dict[str, Any]]:
    """
    Compute dynamic weighted blend of Category Benchmark and Empirical Store Model.

    Formula:
      w = min(1.0, max(0.0, days_of_history / full_history_threshold))
      blended_daily = (1.0 - w) * benchmark + w * store_daily_rate
      total_predicted_demand = blended_daily * horizon_days * festival_multiplier

    Returns:
      (total_predicted_demand, blended_daily, is_cold_start, metadata_dict)
    """
    benchmark = get_category_benchmark(category)

    # Calculate smooth blend weight
    if days_of_history <= 0:
        store_weight = 0.0
    else:
        # Sigmoidal or linear ramp-up
        store_weight = min(1.0, days_of_history / float(full_history_threshold))

    benchmark_weight = 1.0 - store_weight
    blended_daily = (benchmark_weight * benchmark) + (store_weight * max(store_daily_rate, 0.1))
    total_predicted = blended_daily * horizon_days * festival_multiplier

    is_cold_start = days_of_history < 14  # Flagged cold-start if under 2 weeks

    metadata = {
        "days_of_history": days_of_history,
        "benchmark_daily": benchmark,
        "store_statistical_daily": round(store_daily_rate, 2),
        "store_weight": round(store_weight, 3),
        "benchmark_weight": round(benchmark_weight, 3),
        "blended_daily": round(blended_daily, 2),
        "is_cold_start": is_cold_start,
    }

    return round(total_predicted, 1), round(blended_daily, 2), is_cold_start, metadata
