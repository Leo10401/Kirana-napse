"""
Standalone External Keep-Alive Pinger.
Can be run on any external machine, server, or cron runner to ping the Render backend URL every 3-4 minutes.

Usage:
  venv\\Scripts\\python.exe -m scripts.keep_alive_pinger --url https://kirana-backend.onrender.com
"""

import sys
import time
import argparse
import logging
from datetime import datetime, timezone
import requests

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("RenderPinger")


def ping_server(url: str) -> bool:
    """Send health check GET request to target server."""
    if not url.endswith("/health"):
        url = url.rstrip("/") + "/health"

    try:
        t0 = time.time()
        resp = requests.get(url, timeout=25.0)
        elapsed_ms = int((time.time() - t0) * 1000)

        if resp.status_code == 200:
            logger.info(f"Ping SUCCESS: 200 OK from {url} ({elapsed_ms}ms)")
            return True
        else:
            logger.warning(f"Ping WARNING: Status {resp.status_code} from {url}")
            return False
    except Exception as e:
        logger.error(f"Ping FAILED: Could not reach {url}: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description="Render Keep-Alive Automated Pinger")
    parser.add_argument("--url", type=str, default="http://127.0.0.1:8000", help="Base backend URL")
    parser.add_argument("--interval", type=int, default=210, help="Interval in seconds (default: 210s / 3.5 min)")
    parser.add_argument("--once", action="store_true", help="Ping once and exit")

    args = parser.parse_args()
    logger.info(f"Starting Keep-Alive Pinger for {args.url} every {args.interval}s...")

    if args.once:
        ping_server(args.url)
        sys.exit(0)

    while True:
        ping_server(args.url)
        time.sleep(args.interval)


if __name__ == "__main__":
    main()
