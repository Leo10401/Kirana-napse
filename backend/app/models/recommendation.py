"""
Recommendation model — reorder/overstock/expiry suggestions (TRD §6).
"""

import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import String, DateTime, Float, ForeignKey, Text, Enum as SQLEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
import enum

from app.db.base import Base


class RecommendationType(str, enum.Enum):
    REORDER = "reorder"
    LOW_STOCK = "low_stock"
    OVERSTOCK = "overstock"
    EXPIRY_RISK = "expiry_risk"


class RecommendationStatus(str, enum.Enum):
    PENDING = "pending"
    EDITED = "edited"
    ORDERED = "ordered"
    DISMISSED = "dismissed"


class Recommendation(Base):
    __tablename__ = "recommendations"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    store_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("stores.id"), nullable=False, index=True
    )
    forecast_id: Mapped[Optional[str]] = mapped_column(
        String(36), ForeignKey("forecast_runs.id"), nullable=True
    )
    sku_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("skus.id"), nullable=False, index=True
    )
    type: Mapped[str] = mapped_column(
        SQLEnum(RecommendationType), nullable=False
    )
    suggested_qty: Mapped[float] = mapped_column(Float, nullable=False)
    owner_edited_qty: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    reason_text: Mapped[str] = mapped_column(Text, nullable=True)
    reason_text_hi: Mapped[Optional[str]] = mapped_column(Text, nullable=True)  # Hindi version
    status: Mapped[str] = mapped_column(
        SQLEnum(RecommendationStatus), default=RecommendationStatus.PENDING
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    # Relationships
    store = relationship("Store", back_populates="recommendations")
    forecast_run = relationship("ForecastRun", back_populates="recommendations")
    sku = relationship("SKU")
    feedback_flags = relationship("FeedbackFlag", back_populates="recommendation", cascade="all, delete-orphan")
