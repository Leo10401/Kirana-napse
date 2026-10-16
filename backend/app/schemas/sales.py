"""
Sales schemas — request/response models for sales data ingestion.
"""

import datetime as dt
from pydantic import BaseModel, Field


class SalesEntryRequest(BaseModel):
    """Single sales record entry (manual or parsed from OCR)."""
    sku_id: str = Field(..., min_length=1, examples=["existing-item-id"])
    date: dt.date = Field(...)
    quantity_sold: float = Field(..., gt=0, examples=[12.0])
    revenue: float | None = Field(None, ge=0, examples=[600.0])
    source: str = Field("manual", examples=["manual", "ocr", "csv"])


class SalesBulkImportRequest(BaseModel):
    """Bulk import of sales records (CSV/API import)."""
    records: list[SalesEntryRequest]


class SalesRecordResponse(BaseModel):
    id: str
    store_id: str
    sku_id: str
    sku_name: str | None = None
    date: dt.date
    quantity_sold: float
    revenue: float | None
    source: str
    confidence: float
    created_at: dt.datetime

    model_config = {"from_attributes": True}


class StockUpdateRequest(BaseModel):
    """Update current stock level for a SKU."""
    sku_id: str
    quantity_on_hand: float = Field(..., ge=0)
