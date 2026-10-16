"""Refresh the India holiday calendar from a public iCalendar feed."""

import logging
import re
import uuid
from datetime import date, datetime, timedelta, timezone

import httpx
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.config import settings

logger = logging.getLogger(__name__)
SOURCE = "google_india_holidays"
REFRESH_AFTER = timedelta(hours=24)

# These are planning assumptions, not measured effects of the holidays.
DEMAND_MULTIPLIERS = (
    ("diwali", 2.2), ("deepavali", 2.2),
    ("dussehra", 1.8), ("navratri", 1.8),
    ("chhat", 1.9), ("holi", 1.7),
    ("eid-ul-fitr", 1.6), ("eid al-fitr", 1.6), ("ramzan id", 1.6),
    ("raksha bandhan", 1.6), ("ganesh chaturthi", 1.5),
    ("janmashtami", 1.4), ("makar sankranti", 1.4),
    ("pongal", 1.4), ("independence day", 1.3),
    ("republic day", 1.2), ("christmas", 1.3),
)


def demand_multiplier(event_name: str) -> float:
    normalized = event_name.casefold()
    for phrase, multiplier in DEMAND_MULTIPLIERS:
        if phrase in normalized:
            return multiplier
    return 1.0


def parse_ical_events(payload: str) -> list[dict]:
    """Extract all-day events from Google's public holiday ICS feed."""
    if "BEGIN:VCALENDAR" not in payload or "END:VCALENDAR" not in payload:
        raise ValueError("Invalid iCalendar feed")

    # RFC 5545 folds long property values onto a line beginning with whitespace.
    lines = re.sub(r"\r?\n[ \t]", "", payload).splitlines()
    events = []
    fields = None
    for line in lines:
        if line == "BEGIN:VEVENT":
            fields = {}
        elif line == "END:VEVENT" and fields is not None:
            raw_date = fields.get("DTSTART", "")
            name = fields.get("SUMMARY", "").replace(r"\,", ",").replace(r"\;", ";")
            if (re.fullmatch(r"\d{8}", raw_date) and name
                    and fields.get("STATUS") != "CANCELLED"):
                event_date = date.fromisoformat(
                    f"{raw_date[:4]}-{raw_date[4:6]}-{raw_date[6:8]}"
                )
                events.append({
                    "date": event_date.isoformat(),
                    "event_name": name,
                    "uid": fields.get("UID", f"{raw_date}:{name}"),
                    "expected_demand_multiplier": demand_multiplier(name),
                })
            fields = None
        elif fields is not None and ":" in line:
            key, value = line.split(":", 1)
            fields[key.split(";", 1)[0]] = value
    if len(events) < 30:
        raise ValueError("Holiday feed contained too few events")
    return events


async def refresh_holiday_calendar(
    db: AsyncIOMotorDatabase, *, force: bool = False
) -> bool:
    """Refresh at most daily; leave cached events untouched on fetch failure."""
    now = datetime.now(timezone.utc)
    sync = await db.calendar_sync.find_one({"id": SOURCE})
    if not force and sync and sync.get("fetched_at"):
        last = sync["fetched_at"]
        if last.tzinfo is None:
            last = last.replace(tzinfo=timezone.utc)
        if now - last < REFRESH_AFTER:
            return True

    try:
        async with httpx.AsyncClient(timeout=15, follow_redirects=True) as client:
            response = await client.get(settings.HOLIDAY_CALENDAR_ICS_URL)
            response.raise_for_status()
        events = parse_ical_events(response.text)
        covered_years = sorted({int(event["date"][:4]) for event in events})
        if date.today().year not in covered_years:
            raise ValueError("Holiday feed does not cover the current year")
    except (httpx.HTTPError, ValueError) as exc:
        logger.warning("India holiday calendar refresh failed; using cached dates: %s", exc)
        return False

    # Replace only records owned by this feed. Static fallback entries remain.
    await db.festival_calendar_entries.delete_many({"source": SOURCE})
    await db.festival_calendar_entries.insert_many([
        {"id": str(uuid.uuid4()), "source": SOURCE, "region": "National", **event}
        for event in events
    ])
    await db.calendar_sync.update_one(
        {"id": SOURCE},
        {"$set": {"fetched_at": now, "covered_years": covered_years,
                  "event_count": len(events)}},
        upsert=True,
    )
    logger.info("Refreshed %s India holiday dates", len(events))
    return True


async def upcoming_event_context(
    db: AsyncIOMotorDatabase, region: str, start_date: date, end_date: date
) -> tuple[float, str | None]:
    """Return the strongest calendar assumption in the forecast horizon."""
    await refresh_holiday_calendar(db)
    sync = await db.calendar_sync.find_one({"id": SOURCE})
    covered_years = set(sync.get("covered_years", [])) if sync else set()
    years = set(range(start_date.year, end_date.year + 1))
    if years.issubset(covered_years):
        source_query = {"source": SOURCE}
    else:
        # Legacy fixed entries are only a fallback for their actual year.
        source_query = {"source": {"$exists": False}}

    cursor = db.festival_calendar_entries.find({
        **source_query,
        "region": {"$in": [region, "National", "All"]},
        "date": {"$gte": start_date.isoformat(), "$lte": end_date.isoformat()},
    })
    events = await cursor.to_list(length=200)
    best = max(events, key=lambda event: event.get("expected_demand_multiplier", 1.0), default=None)
    multiplier = best.get("expected_demand_multiplier", 1.0) if best else 1.0
    name = best["event_name"] if best and multiplier > 1.0 else None

    # The first-of-month payday assumption follows the calendar every year.
    if any(day.day == 1 for day in (
        start_date + timedelta(days=offset)
        for offset in range((end_date - start_date).days + 1)
    )) and multiplier < 1.25:
        return 1.25, "Month-start payday"
    return multiplier, name
