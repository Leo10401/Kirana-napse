"""
Base interface and standardized output structures for forecasting models.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Dict, Any, List, Optional
import pandas as pd


@dataclass
class ForecastOutput:
    predicted_demand: float
    daily_base_demand: float
    confidence_lower: float
    confidence_upper: float
    model_version: str
    cold_start_flag: bool
    trend_direction: str = "steady"  # "upward", "downward", "steady"
    primary_drivers: List[str] = field(default_factory=list)
    reason_en: str = ""
    reason_hi: str = ""
    diagnostics: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "predicted_demand": round(float(self.predicted_demand), 1),
            "daily_base_demand": round(float(self.daily_base_demand), 1),
            "confidence_lower": round(float(self.confidence_lower), 1),
            "confidence_upper": round(float(self.confidence_upper), 1),
            "model_version": self.model_version,
            "cold_start_flag": bool(self.cold_start_flag),
            "trend_direction": self.trend_direction,
            "primary_drivers": self.primary_drivers,
            "reason_en": self.reason_en,
            "reason_hi": self.reason_hi,
            "diagnostics": self.diagnostics,
        }


class BaseForecaster(ABC):
    """Abstract base class for all Kirana demand forecasters."""

    @abstractmethod
    def fit_predict(
        self,
        series: pd.Series,
        horizon_days: int = 7,
        **kwargs
    ) -> ForecastOutput:
        """
        Fit model on historical series and generate multi-step demand forecast.
        """
        pass
