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

_START_TIME = time.time()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for MongoDB connection and background keep-alive job."""
    await connect_to_mongo()
    # Start automated keep-alive heartbeat worker (every 3-4 minutes)
    keep_alive_task = start_keep_alive_task()

    yield

    # Clean shutdown
    if keep_alive_task and not keep_alive_task.done():
        keep_alive_task.cancel()
        try:
            await keep_alive_task
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
