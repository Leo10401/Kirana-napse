"""
SalesRecord model — daily per-SKU sales data (TRD §6).
"""

import uuid
from datetime import datetime, date, timezone

from sqlalchemy import String, DateTime, Date, Integer, Float, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
import enum

from app.db.base import Base


class SalesSource(str, enum.Enum):
    MANUAL = "manual"
    OCR = "ocr"
    CSV = "csv"
    API = "api"


class SalesRecord(Base):
    __tablename__ = "sales_records"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    store_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("stores.id"), nullable=False, index=True
    )
    sku_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("skus.id"), nullable=False, index=True
    )
    date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    quantity_sold: Mapped[float] = mapped_column(Float, nullable=False)
    revenue: Mapped[float] = mapped_column(Float, nullable=True)
    source: Mapped[str] = mapped_column(
        SQLEnum(SalesSource), default=SalesSource.MANUAL
    )
    confidence: Mapped[float] = mapped_column(Float, default=1.0)  # 0.0-1.0
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    # Relationships
    store = relationship("Store", back_populates="sales_records")
    sku = relationship("SKU", back_populates="sales_records")
