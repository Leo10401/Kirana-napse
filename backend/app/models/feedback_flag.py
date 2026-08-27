"""
FeedbackFlag model — owner-submitted 'forecast was wrong' flags (TRD §6).
"""

import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import String, DateTime, ForeignKey, Text, Enum as SQLEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
import enum

from app.db.base import Base


class FeedbackReasonCode(str, enum.Enum):
    FESTIVAL_EVENT = "festival_event"
    BULK_BUYER = "bulk_buyer"
    WEATHER = "weather"
    COMPETITOR_PRICE = "competitor_price"
    OTHER = "other"


class FeedbackFlag(Base):
    __tablename__ = "feedback_flags"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    recommendation_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("recommendations.id"), nullable=False, index=True
    )
    reason_code: Mapped[str] = mapped_column(
        SQLEnum(FeedbackReasonCode), nullable=False
    )
    free_text: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    submitted_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    # Relationships
    recommendation = relationship("Recommendation", back_populates="feedback_flags")
