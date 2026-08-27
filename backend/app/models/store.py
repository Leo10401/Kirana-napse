"""
Store model — kirana store profile (TRD §6).
"""

import uuid
from datetime import datetime, timezone

from sqlalchemy import String, DateTime, Integer, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
import enum

from app.db.base import Base


class StoreStatus(str, enum.Enum):
    INCOMPLETE = "incomplete"
    ACTIVE = "active"
    INACTIVE = "inactive"


class OnboardingSource(str, enum.Enum):
    ORGANIC = "organic"
    REFERRAL = "referral"
    FIELD_AGENT = "field_agent"


class TrackingMethod(str, enum.Enum):
    NOTHING = "nothing"
    PAPER_REGISTER = "paper_register"
    BILLING_APP = "billing_app"


class Store(Base):
    __tablename__ = "stores"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    owner_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id"), nullable=False
    )
    owner_name: Mapped[str] = mapped_column(String(100), nullable=True)
    store_name: Mapped[str] = mapped_column(String(200), nullable=True)
    category: Mapped[str] = mapped_column(String(100), nullable=True)
    sku_count_estimate: Mapped[int] = mapped_column(Integer, nullable=True)
    city: Mapped[str] = mapped_column(String(100), nullable=True)
    region: Mapped[str] = mapped_column(String(100), nullable=True)
    language_pref: Mapped[str] = mapped_column(String(10), default="hi")  # hi, en, etc.
    tracking_method: Mapped[str] = mapped_column(
        SQLEnum(TrackingMethod), nullable=True
    )
    onboarding_source: Mapped[str] = mapped_column(
        SQLEnum(OnboardingSource), default=OnboardingSource.ORGANIC
    )
    status: Mapped[str] = mapped_column(
        SQLEnum(StoreStatus), default=StoreStatus.INCOMPLETE
    )
    notification_enabled: Mapped[bool] = mapped_column(default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    # Relationships
    owner = relationship("User", back_populates="stores")
    skus = relationship("SKU", back_populates="store", cascade="all, delete-orphan")
    sales_records = relationship("SalesRecord", back_populates="store", cascade="all, delete-orphan")
    stock_levels = relationship("StockLevel", back_populates="store", cascade="all, delete-orphan")
    recommendations = relationship("Recommendation", back_populates="store", cascade="all, delete-orphan")
    device_tokens = relationship("DeviceToken", back_populates="store", cascade="all, delete-orphan")
    notification_logs = relationship("NotificationLog", back_populates="store", cascade="all, delete-orphan")
    install_events = relationship("InstallEvent", back_populates="store", cascade="all, delete-orphan")
    consent_records = relationship("ConsentRecord", back_populates="store", cascade="all, delete-orphan")
