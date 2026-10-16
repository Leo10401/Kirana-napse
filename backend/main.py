"""
Kirana-Napse Backend — FastAPI Application Entry Point (MongoDB / Atlas Edition)
AI-Powered Demand Forecasting & Reorder Assistant for Kirana Stores
"""

import time
import asyncio
from datetime import datetime, timezone
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.api import router as api_router
from app.db.mongodb import connect_to_mongo, close_mongo_connection
from app.services.keep_alive import start_keep_alive_task
from app.services.holiday_calendar import refresh_holiday_calendar
from app.services.forecasting import run_forecast_for_store

_START_TIME = time.time()


async def _refresh_daily_data():
    """Refresh holidays and stale store forecasts in the background."""
    from app.db.mongodb import get_database
    while True:
        try:
            db = await get_database()
            await refresh_holiday_calendar(db)
            today = datetime.now().date().isoformat()
            stores = await db.stores.find({"status": "active"}).to_list(length=None)
            for store in stores:
                store_id = store["id"]
                latest = await db.forecast_runs.find_one(
                    {"store_id": store_id}, sort=[("run_date", -1)]
                )
                if latest and latest["run_date"] >= today:
                    continue
                if not await db.skus.find_one({"store_id": store_id}):
                    continue
                try:
                    await run_forecast_for_store(
                        db, store_id, region=store.get("region") or "National"
                    )
                except Exception as exc:
                    import logging
                    logging.getLogger(__name__).warning(
                        "Daily forecast failed for store %s: %s", store_id, exc
                    )
        except Exception as exc:
            import logging
            logging.getLogger(__name__).warning("Daily data refresh error: %s", exc)
        await asyncio.sleep(60 * 60)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for MongoDB connection and background keep-alive job."""
    await connect_to_mongo()
    # Start automated keep-alive heartbeat worker (every 3-4 minutes)
    keep_alive_task = start_keep_alive_task()
    holiday_task = asyncio.create_task(_refresh_daily_data())

    yield

    # Clean shutdown
    if keep_alive_task and not keep_alive_task.done():
        keep_alive_task.cancel()
        try:
            await keep_alive_task
        except asyncio.CancelledError:
            pass

    holiday_task.cancel()
    try:
        await holiday_task
    except asyncio.CancelledError:
        pass

    await close_mongo_connection()


app = FastAPI(
    title="Kirana-Napse API",
    description="AI-Powered Demand Forecasting & Reorder Assistant for Kirana Stores (MongoDB Edition)",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# CORS — allow the Flutter app and external clients to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include all API routes
app.include_router(api_router, prefix="/api/v1")


@app.get("/", tags=["Health"])
async def root():
    return {
        "name": "Kirana-Napse API",
        "version": "2.0.0",
        "database": "MongoDB / MongoDB Atlas",
        "status": "running",
        "keep_alive_enabled": settings.KEEP_ALIVE_ENABLED,
    }


@app.get("/health", tags=["Health"])
async def health_check():
    """Health check endpoint pinged every 3-4 minutes to keep Render alive."""
    uptime_seconds = int(time.time() - _START_TIME)
    return {
        "status": "healthy",
        "database": "connected",
        "uptime_seconds": uptime_seconds,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "environment": settings.APP_ENV,
    }
