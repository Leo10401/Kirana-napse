"""
Recommendation schemas — request/response models for recommendations.
"""

from datetime import datetime
from pydantic import BaseModel, Field


class RecommendationResponse(BaseModel):
    id: str
    store_id: str
    sku_id: str
    sku_name: str | None = None
    sku_category: str | None = None
    sku_unit: str | None = None
    type: str  # reorder, low_stock, overstock, expiry_risk
    suggested_qty: float
    owner_edited_qty: float | None
    reason_text: str | None
    reason_text_hi: str | None
    status: str  # pending, edited, ordered, dismissed
    cold_start: bool = False
    created_at: datetime

    model_config = {"from_attributes": True}


class RecommendationUpdateRequest(BaseModel):
    """Owner edits a recommendation (edit qty, mark ordered, dismiss)."""
    owner_edited_qty: float | None = Field(None, ge=0)
    status: str = Field(..., examples=["edited", "ordered", "dismissed"])


class TodayRecommendationsResponse(BaseModel):
    """Aggregated response for /recommendations/today endpoint."""
    store_id: str
    date: str
    reorder_count: int
    overstock_count: int
    expiry_risk_count: int
    low_stock_count: int
    recommendations: list[RecommendationResponse]
    last_updated: datetime


class FeedbackFlagRequest(BaseModel):
    """Owner submits a 'forecast was wrong' flag."""
    reason_code: str = Field(..., examples=["festival_event", "bulk_buyer", "weather", "other"])
    free_text: str | None = Field(None, examples=["Diwali rush was bigger than expected"])


class FeedbackFlagResponse(BaseModel):
    id: str
    recommendation_id: str
    reason_code: str
    free_text: str | None
    submitted_at: datetime

    model_config = {"from_attributes": True}
