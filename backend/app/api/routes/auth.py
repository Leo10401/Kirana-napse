"""
Auth routes — registration and login with MongoDB (TRD §7).
"""

import uuid
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.db.mongodb import get_database
from app.schemas.auth import RegisterRequest, LoginRequest, TokenResponse, UserResponse
from app.core.security import hash_password, verify_password, create_access_token

router = APIRouter()


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(request: RegisterRequest, db: AsyncIOMotorDatabase = Depends(get_database)):
    """Register a new store owner with phone and password."""
    # Check if phone already registered
    existing_user = await db.users.find_one({"phone": request.phone})
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Phone number already registered",
        )

    user_id = str(uuid.uuid4())
    store_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc)

    # Create user doc
    user_doc = {
        "id": user_id,
        "phone": request.phone,
        "password_hash": hash_password(request.password),
        "name": request.name,
        "is_active": True,
        "created_at": now,
        "updated_at": now,
    }
    await db.users.insert_one(user_doc)

    # Create empty store shell
    store_doc = {
        "id": store_id,
        "owner_id": user_id,
        "owner_name": request.name,
        "store_name": None,
        "category": None,
        "sku_count_estimate": None,
        "city": None,
        "region": None,
        "language_pref": "hi",
        "tracking_method": None,
        "onboarding_source": "organic",
        "status": "incomplete",
        "notification_enabled": True,
        "created_at": now,
        "updated_at": now,
    }
    await db.stores.insert_one(store_doc)

    token = create_access_token({"sub": user_id, "store_id": store_id})

    return TokenResponse(
        access_token=token,
        user_id=user_id,
        store_id=store_id,
    )


@router.post("/login", response_model=TokenResponse)
async def login(request: LoginRequest, db: AsyncIOMotorDatabase = Depends(get_database)):
    """Login with phone and password."""
    user = await db.users.find_one({"phone": request.phone})
    if not user or not verify_password(request.password, user.get("password_hash", "")):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid phone number or password",
        )

    store = await db.stores.find_one({"owner_id": user["id"]})
    store_id = store["id"] if store else None

    token = create_access_token({
        "sub": user["id"],
        "store_id": store_id,
    })

    return TokenResponse(
        access_token=token,
        user_id=user["id"],
        store_id=store_id,
    )
