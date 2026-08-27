"""
Render / Cloud Keep-Alive Service.
Runs an automated background heartbeat ping every 3-4 minutes to prevent Render free-tier
servers from deactivating or spinning down due to inactivity.
"""

import asyncio
import logging
from datetime import datetime, timezone
from typing import Optional
import httpx

from app.core.config import settings

logger = logging.getLogger("keep_alive")
logging.basicConfig(level=logging.INFO)


def get_target_ping_url() -> str:
    """Determine the public or local target health check URL."""
    base_url = settings.KEEP_ALIVE_URL or settings.RENDER_EXTERNAL_URL
    if base_url:
        base_url = base_url.rstrip("/")
        return f"{base_url}/health"
    # Local fallback
    return f"http://127.0.0.1:{settings.PORT}/health"


async def keep_alive_loop(
    interval_seconds: int = 210,
    target_url: Optional[str] = None
):
    """
    Background worker loop that sends HTTP GET health check pings every 3-4 minutes.
    """
    url = target_url or get_target_ping_url()
    logger.info(f"[Keep-Alive] Initialized heartbeat worker targeting: {url} (interval: {interval_seconds}s)")

    # Wait 10 seconds on startup for server initialization
    await asyncio.sleep(10)

    async with httpx.AsyncClient(timeout=20.0) as client:
        while True:
            try:
                start_time = datetime.now(timezone.utc)
                resp = await client.get(url)
                latency_ms = int((datetime.now(timezone.utc) - start_time).total_seconds() * 1000)

                if resp.status_code == 200:
                    logger.info(f"[Keep-Alive Ping] OK status 200 from {url} ({latency_ms}ms) at {start_time.isoformat()}")
                else:
                    logger.warning(f"[Keep-Alive Ping] Warning: Received status {resp.status_code} from {url}")
            except asyncio.CancelledError:
                logger.info("[Keep-Alive] Heartbeat worker received cancellation signal. Stopping cleanly.")
                break
            except Exception as e:
                logger.warning(f"[Keep-Alive Ping] Could not connect to {url}: {e}")

            # Sleep for the configured interval (e.g. 210s = 3.5 minutes)
            try:
                await asyncio.sleep(interval_seconds)
            except asyncio.CancelledError:
                break


def start_keep_alive_task() -> Optional[asyncio.Task]:
    """Spawn the keep-alive background task if enabled in configuration."""
    if not settings.KEEP_ALIVE_ENABLED:
        logger.info("[Keep-Alive] Service is disabled via configuration.")
        return None

    task = asyncio.create_task(
        keep_alive_loop(interval_seconds=settings.KEEP_ALIVE_INTERVAL_SECONDS)
    )
    return task
