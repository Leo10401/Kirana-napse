"""
NotificationLog model — tracks push notification delivery status (TRD §6).
"""

import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import String, DateTime, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
import enum

from app.db.base import Base


class NotificationType(str, enum.Enum):
    DAILY_SUMMARY = "daily_summary"
    LOW_STOCK_ALERT = "low_stock_alert"
    OVERSTOCK_EXPIRY_ALERT = "overstock_expiry_alert"
    FEEDBACK_PROMPT = "feedback_prompt"


class NotificationStatus(str, enum.Enum):
    SENT = "sent"
    DELIVERED = "delivered"
    OPENED = "opened"
    FAILED = "failed"


class NotificationLog(Base):
    __tablename__ = "notification_logs"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    store_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("stores.id"), nullable=False, index=True
    )
    device_token_id: Mapped[Optional[str]] = mapped_column(
        String(36), ForeignKey("device_tokens.id"), nullable=True
    )
    type: Mapped[str] = mapped_column(
        SQLEnum(NotificationType), nullable=False
    )
    title: Mapped[str] = mapped_column(String(200), nullable=True)
    body: Mapped[str] = mapped_column(String(500), nullable=True)
    deep_link: Mapped[Optional[str]] = mapped_column(String(300), nullable=True)
    status: Mapped[str] = mapped_column(
        SQLEnum(NotificationStatus), default=NotificationStatus.SENT
    )
    sent_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    delivered_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    opened_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # Relationships
    store = relationship("Store", back_populates="notification_logs")
