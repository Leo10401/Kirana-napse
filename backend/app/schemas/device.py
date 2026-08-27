"""
Device and notification schemas.
"""

from datetime import datetime
from pydantic import BaseModel, Field


class DeviceTokenRequest(BaseModel):
    """Register or refresh an FCM device token."""
    fcm_token: str = Field(...)
    device_model: str | None = Field(None, examples=["Samsung Galaxy M13"])
    os_version: str | None = Field(None, examples=["Android 13"])


class DeviceTokenResponse(BaseModel):
    id: str
    store_id: str
    fcm_token: str
    device_model: str | None
    os_version: str | None
    registered_at: datetime

    model_config = {"from_attributes": True}


class InstallEventRequest(BaseModel):
    """Track app install/uninstall/reinstall events."""
    event_type: str = Field(..., examples=["installed", "uninstalled", "reinstalled"])
    device_model: str | None = Field(None, examples=["Samsung Galaxy M13"])


class NotificationStatusUpdate(BaseModel):
    """Update notification delivery status (from client)."""
    notification_id: str
    status: str = Field(..., examples=["delivered", "opened"])
