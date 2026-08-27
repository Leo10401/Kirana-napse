"""
SKU model — individual product in a store (TRD §6).
"""

import uuid
from datetime import datetime, date, timezone
from typing import Optional

from sqlalchemy import String, DateTime, Date, Integer, Float, Boolean, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class SKU(Base):
    __tablename__ = "skus"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    store_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("stores.id"), nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    category: Mapped[str] = mapped_column(String(100), nullable=True)
    unit: Mapped[str] = mapped_column(String(50), default="pcs")  # pcs, kg, ltr, etc.
    is_perishable: Mapped[bool] = mapped_column(Boolean, default=False)
    expiry_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    supplier_lead_time_days: Mapped[int] = mapped_column(Integer, default=2)
    barcode: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    # Relationships
    store = relationship("Store", back_populates="skus")
    sales_records = relationship("SalesRecord", back_populates="sku", cascade="all, delete-orphan")
    stock_levels = relationship("StockLevel", back_populates="sku", cascade="all, delete-orphan")
    forecast_runs = relationship("ForecastRun", back_populates="sku", cascade="all, delete-orphan")
