"""
Application configuration loaded from environment variables (MongoDB Atlas supported).
"""

from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    # App
    APP_ENV: str = "development"
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    # MongoDB / MongoDB Atlas
    MONGODB_URL: str = "mongodb://localhost:27017"
    MONGODB_DB_NAME: str = "kirana_napse"
    HOLIDAY_CALENDAR_ICS_URL: str = "https://calendar.google.com/calendar/ical/en.indian%23holiday%40group.v.calendar.google.com/public/basic.ics"

    # JWT Auth
    JWT_SECRET: str = "kirana-napse-dev-secret-change-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRATION_HOURS: int = 168  # 7 days

    # Firebase
    FIREBASE_PROJECT_ID: Optional[str] = None
    FIREBASE_CREDENTIALS_PATH: Optional[str] = None

    # Render / Cloud Keep-Alive Settings (Ping every 3-4 minutes to prevent idle spin-down)
    RENDER_EXTERNAL_URL: Optional[str] = None
    KEEP_ALIVE_URL: Optional[str] = None
    KEEP_ALIVE_ENABLED: bool = True
    KEEP_ALIVE_INTERVAL_SECONDS: int = 210  # 3.5 minutes (210 seconds)

    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "allow"


settings = Settings()
