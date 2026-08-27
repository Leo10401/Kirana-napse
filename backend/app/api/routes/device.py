"""
Device & notification routes with MongoDB (TRD §7, §8).
"""

import uuid
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.db.mongodb import get_database
from app.schemas.device import (
    DeviceTokenRequest,
    DeviceTokenResponse,
    InstallEventRequest,
    NotificationStatusUpdate,
)
from app.core.security import get_current_user

router = APIRouter()


@router.post("/{store_id}/device-tokens", response_model=DeviceTokenResponse, status_code=201)
async def register_device_token(
    store_id: str,
    request: DeviceTokenRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """Register or refresh an FCM device token for push delivery (TRD §5.5)."""
    if current_user["store_id"] != store_id:
        raise HTTPException(status_code=403, detail="Not authorized for this store")

    now = datetime.now(timezone.utc)
    existing = await db.device_tokens.find_one({"fcm_token": request.fcm_token})

    if existing:
        await db.device_tokens.update_one(
            {"fcm_token": request.fcm_token},
            {
                "$set": {
                    "store_id": store_id,
                    "device_model": request.device_model or existing.get("device_model"),
                    "os_version": request.os_version or existing.get("os_version"),
                    "last_active_at": now,
                }
            }
        )
        updated = await db.device_tokens.find_one({"fcm_token": request.fcm_token})
        return DeviceTokenResponse(**updated)

    token_id = str(uuid.uuid4())
    token_doc = {
        "id": token_id,
        "store_id": store_id,
        "fcm_token": request.fcm_token,
        "device_model": request.device_model,
        "os_version": request.os_version,
        "registered_at": now,
        "last_active_at": now,
    }
    await db.device_tokens.insert_one(token_doc)
    return DeviceTokenResponse(**token_doc)


@router.post("/{store_id}/install-events", status_code=201)
async def record_install_event(
    store_id: str,
    request: InstallEventRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """Track app install/uninstall/reinstall events (TRD §10)."""
    if current_user["store_id"] != store_id:
        raise HTTPException(status_code=403, detail="Not authorized for this store")

    event_doc = {
        "id": str(uuid.uuid4()),
        "store_id": store_id,
        "event_type": request.event_type,
        "device_model": request.device_model,
        "occurred_at": datetime.now(timezone.utc),
    }
    await db.install_events.insert_one(event_doc)
    return {"status": "recorded", "event_type": request.event_type}


@router.patch("/notifications/status")
async def update_notification_status(
    request: NotificationStatusUpdate,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """Update notification delivery/open status from client."""
    now = datetime.now(timezone.utc)
    update_data: dict = {"status": request.status}
    if request.status == "delivered":
        update_data["delivered_at"] = now
    elif request.status == "opened":
        update_data["opened_at"] = now

    result = await db.notification_logs.update_one(
        {"id": request.notification_id},
        {"$set": update_data}
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Notification not found")

    return {"status": "updated"}
