"""
InstallEvent model — tracks app install/uninstall churn signals (TRD §6).
"""

import uuid
from datetime import datetime, timezone

from sqlalchemy import String, DateTime, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
import enum

from app.db.base import Base


class InstallEventType(str, enum.Enum):
    INSTALLED = "installed"
    UNINSTALLED = "uninstalled"
    REINSTALLED = "reinstalled"


class InstallEvent(Base):
    __tablename__ = "install_events"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    store_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("stores.id"), nullable=False, index=True
    )
    event_type: Mapped[str] = mapped_column(
        SQLEnum(InstallEventType), nullable=False
    )
    device_model: Mapped[str] = mapped_column(String(100), nullable=True)
    occurred_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    # Relationships
    store = relationship("Store", back_populates="install_events")
