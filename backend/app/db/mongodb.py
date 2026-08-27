"""
MongoDB / MongoDB Atlas Async Client using Motor.
Provides database connection management and FastAPI dependency injection.
"""

from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from typing import Optional
from app.core.config import settings

client: Optional[AsyncIOMotorClient] = None
db: Optional[AsyncIOMotorDatabase] = None


async def connect_to_mongo():
    """Initialize MongoDB connection on app startup."""
    global client, db
    client = AsyncIOMotorClient(
        settings.MONGODB_URL,
        serverSelectionTimeoutMS=5000,
    )
    db = client[settings.MONGODB_DB_NAME]

    # Create indexes for optimal performance (TRD §6)
    try:
        await db.users.create_index("phone", unique=True)
        await db.stores.create_index("owner_id")
        await db.skus.create_index([("store_id", 1), ("name", 1)])
        await db.sales_records.create_index([("store_id", 1), ("sku_id", 1), ("date", -1)])
        await db.stock_levels.create_index([("store_id", 1), ("sku_id", 1)])
        await db.forecast_runs.create_index([("store_id", 1), ("sku_id", 1), ("run_date", -1)])
        await db.recommendations.create_index([("store_id", 1), ("type", 1), ("status", 1)])
        await db.device_tokens.create_index("fcm_token", unique=True)
        await db.festival_calendar_entries.create_index([("region", 1), ("date", 1)])
    except Exception as e:
        print(f"MongoDB index check/creation note: {e}")

    # Auto-seed festival calendar entries if database is fresh
    try:
        from app.db.init_db import FESTIVALS_SEED
        festival_count = await db.festival_calendar_entries.count_documents({})
        if festival_count == 0:
            await db.festival_calendar_entries.insert_many(FESTIVALS_SEED)
            print(f"[OK] Auto-seeded {len(FESTIVALS_SEED)} festival calendar events on startup.")
    except Exception as e:
        print(f"Festival calendar auto-seed note: {e}")


async def close_mongo_connection():
    """Close MongoDB connection on app shutdown."""
    global client
    if client:
        client.close()


async def get_database() -> AsyncIOMotorDatabase:
    """FastAPI dependency to inject MongoDB database."""
    global db, client
    if db is None:
        client = AsyncIOMotorClient(settings.MONGODB_URL)
        db = client[settings.MONGODB_DB_NAME]
    return db
