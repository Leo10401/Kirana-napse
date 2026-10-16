"""Catalog item and current stock request/response models."""

import datetime as dt
from pydantic import BaseModel, Field, field_validator


class ItemCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    category: str = Field("grocery", min_length=1, max_length=80)
    unit: str = Field("pcs", min_length=1, max_length=20)
    quantity_on_hand: float | None = Field(None, ge=0)
    supplier_lead_time_days: int = Field(2, ge=1, le=365)

    @field_validator("name", "category", "unit")
    @classmethod
    def strip_required_text(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("Cannot be blank")
        return value


class ItemResponse(BaseModel):
    id: str
    store_id: str
    name: str
    category: str | None
    unit: str
    quantity_on_hand: float | None
    supplier_lead_time_days: int
    created_at: dt.datetime
