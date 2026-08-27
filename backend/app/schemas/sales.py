"""
Sales schemas — request/response models for sales data ingestion.
"""

import datetime as dt
from pydantic import BaseModel, Field


class SalesEntryRequest(BaseModel):
    """Single sales record entry (manual or parsed from OCR)."""
    sku_name: str = Field(..., examples=["Amul Butter 500g"])
    sku_category: str | None = Field(None, examples=["dairy"])
    date: dt.date = Field(...)
    quantity_sold: float = Field(..., gt=0, examples=[12.0])
    revenue: float | None = Field(None, examples=[600.0])
    unit: str = Field("pcs", examples=["pcs", "kg", "ltr"])
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
