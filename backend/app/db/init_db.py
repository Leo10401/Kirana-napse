"""
MongoDB Database Initialization and Festival Seeder (TRD §5.4).
"""

import asyncio
from datetime import date
from motor.motor_asyncio import AsyncIOMotorClient
from app.core.config import settings

FESTIVALS_SEED = [
    {"region": "National", "date": "2026-01-14", "event_name": "Makar Sankranti / Pongal", "event_name_hi": "मकर संक्रांति / पोंगल", "expected_demand_multiplier": 1.4},
    {"region": "National", "date": "2026-01-26", "event_name": "Republic Day", "event_name_hi": "गणतंत्र दिवस", "expected_demand_multiplier": 1.2},
    {"region": "National", "date": "2026-03-04", "event_name": "Holi", "event_name_hi": "होली", "expected_demand_multiplier": 1.7},
    {"region": "National", "date": "2026-03-20", "event_name": "Eid-ul-Fitr", "event_name_hi": "ईद-उल-फ़ित्र", "expected_demand_multiplier": 1.6},
    {"region": "National", "date": "2026-08-15", "event_name": "Independence Day", "event_name_hi": "स्वतंत्रता दिवस", "expected_demand_multiplier": 1.3},
    {"region": "National", "date": "2026-08-28", "event_name": "Raksha Bandhan", "event_name_hi": "रक्षाबंधन", "expected_demand_multiplier": 1.6},
    {"region": "National", "date": "2026-09-04", "event_name": "Janmashtami", "event_name_hi": "जन्माष्टमी", "expected_demand_multiplier": 1.4},
    {"region": "National", "date": "2026-09-14", "event_name": "Ganesh Chaturthi", "event_name_hi": "गणेश चतुर्थी", "expected_demand_multiplier": 1.5},
    {"region": "National", "date": "2026-10-20", "event_name": "Dussehra / Navratri", "event_name_hi": "दशहरा / नवरात्रि", "expected_demand_multiplier": 1.8},
    {"region": "National", "date": "2026-11-08", "event_name": "Diwali", "event_name_hi": "दीपावली", "expected_demand_multiplier": 2.2},
    {"region": "National", "date": "2026-11-10", "event_name": "Bhai Dooj", "event_name_hi": "भाई दूज", "expected_demand_multiplier": 1.4},
    {"region": "National", "date": "2026-11-15", "event_name": "Chhath Puja", "event_name_hi": "छठ पूजा", "expected_demand_multiplier": 1.9},
    {"region": "National", "date": "2026-12-25", "event_name": "Christmas", "event_name_hi": "क्रिसमस", "expected_demand_multiplier": 1.3},
    {"region": "National", "date": "2026-09-01", "event_name": "Month-Start Payday Surge", "event_name_hi": "महीने की शुरुआत वेतन वृद्धि", "expected_demand_multiplier": 1.25},
    {"region": "National", "date": "2026-10-01", "event_name": "Month-Start Payday Surge", "event_name_hi": "महीने की शुरुआत वेतन वृद्धि", "expected_demand_multiplier": 1.25},
    {"region": "National", "date": "2026-11-01", "event_name": "Month-Start Payday Surge", "event_name_hi": "महीने की शुरुआत वेतन वृद्धि", "expected_demand_multiplier": 1.25},
]


async def seed_festivals():
    """Seed festival calendar into MongoDB."""
    client = AsyncIOMotorClient(settings.MONGODB_URL)
    db = client[settings.MONGODB_DB_NAME]

    count = 0
    for f in FESTIVALS_SEED:
        existing = await db.festival_calendar_entries.find_one({
            "region": f["region"],
            "date": f["date"],
            "event_name": f["event_name"],
        })
        if not existing:
            await db.festival_calendar_entries.insert_one(f)
            count += 1

    print(f"[OK] Seeded {count} new festival calendar events in MongoDB.")
    client.close()


if __name__ == "__main__":
    asyncio.run(seed_festivals())
