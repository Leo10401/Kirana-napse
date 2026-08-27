"""
Store schemas — request/response models for store profile and onboarding.
"""

from datetime import datetime
from pydantic import BaseModel, Field


class OnboardingRequest(BaseModel):
    """Data collected during the in-app onboarding flow (AppFlow §4.3)."""
    store_name: str | None = Field(None, examples=["Ramesh General Store"])
    owner_name: str | None = Field(None, examples=["Ramesh Kumar"])
    category: str = Field(..., examples=["general", "grocery", "pharmacy", "snacks"])
    sku_count_estimate: int | None = Field(None, ge=0, le=5000, examples=[500])
    city: str = Field(..., examples=["Lucknow"])
    region: str | None = Field(None, examples=["Uttar Pradesh"])
    language_pref: str = Field("hi", examples=["hi", "en"])
    tracking_method: str = Field(..., examples=["nothing", "paper_register", "billing_app"])
    notification_enabled: bool = Field(True)
    onboarding_source: str = Field("organic", examples=["organic", "referral", "field_agent"])


class StoreResponse(BaseModel):
    id: str
    owner_id: str
    store_name: str | None
    owner_name: str | None
    category: str | None
    sku_count_estimate: int | None
    city: str | None
    region: str | None
    language_pref: str
    tracking_method: str | None
    status: str
    notification_enabled: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class StoreUpdateRequest(BaseModel):
    store_name: str | None = None
    language_pref: str | None = None
    notification_enabled: bool | None = None
    city: str | None = None
    region: str | None = None
