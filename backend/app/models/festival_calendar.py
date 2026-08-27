"""
FestivalCalendarEntry model — regional events that affect demand (TRD §6).
"""

import uuid
from datetime import date

from sqlalchemy import String, Date, Float
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class FestivalCalendarEntry(Base):
    __tablename__ = "festival_calendar_entries"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    region: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    event_name: Mapped[str] = mapped_column(String(200), nullable=False)
    event_name_hi: Mapped[str] = mapped_column(String(200), nullable=True)
    expected_demand_multiplier: Mapped[float] = mapped_column(Float, default=1.0)
