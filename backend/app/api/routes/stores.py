"""
Store routes — onboarding and profile management with MongoDB (TRD §7).
"""

from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.db.mongodb import get_database
from app.schemas.store import OnboardingRequest, StoreResponse, StoreUpdateRequest
from app.core.security import get_current_user

router = APIRouter()


@router.post("/{store_id}/onboarding", response_model=StoreResponse)
async def complete_onboarding(
    store_id: str,
    request: OnboardingRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """
    Complete onboarding flow (AppFlow §4.3).
    Saves store basics, sets status to 'active'.
    """
    store = await db.stores.find_one({"id": store_id})
    if not store:
        raise HTTPException(status_code=404, detail="Store not found")
    if store.get("owner_id") != current_user["user_id"]:
        raise HTTPException(status_code=403, detail="Not authorized for this store")

    now = datetime.now(timezone.utc)
    update_fields = {
        "store_name": request.store_name or store.get("store_name"),
        "owner_name": request.owner_name or store.get("owner_name"),
        "category": request.category,
        "sku_count_estimate": request.sku_count_estimate,
        "city": request.city,
        "region": request.region or request.city,
        "language_pref": request.language_pref,
        "tracking_method": request.tracking_method,
        "notification_enabled": request.notification_enabled,
        "onboarding_source": request.onboarding_source,
        "status": "active",
        "updated_at": now,
    }

    await db.stores.update_one({"id": store_id}, {"$set": update_fields})
    updated_store = await db.stores.find_one({"id": store_id})
    return StoreResponse(**updated_store)


@router.get("/{store_id}", response_model=StoreResponse)
async def get_store(
    store_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """Get store profile."""
    store = await db.stores.find_one({"id": store_id})
    if not store:
        raise HTTPException(status_code=404, detail="Store not found")
    if store.get("owner_id") != current_user["user_id"]:
        raise HTTPException(status_code=403, detail="Not authorized for this store")

    return StoreResponse(**store)


@router.patch("/{store_id}", response_model=StoreResponse)
async def update_store(
    store_id: str,
    request: StoreUpdateRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """Update store settings."""
    store = await db.stores.find_one({"id": store_id})
    if not store:
        raise HTTPException(status_code=404, detail="Store not found")
    if store.get("owner_id") != current_user["user_id"]:
        raise HTTPException(status_code=403, detail="Not authorized for this store")

    update_data = request.model_dump(exclude_unset=True)
    if update_data:
        update_data["updated_at"] = datetime.now(timezone.utc)
        await db.stores.update_one({"id": store_id}, {"$set": update_data})

    updated_store = await db.stores.find_one({"id": store_id})
    return StoreResponse(**updated_store)
