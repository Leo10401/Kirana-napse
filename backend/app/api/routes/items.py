"""Store catalog. Sales reference these item IDs."""

import re
import uuid
from datetime import date, datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.security import get_current_user
from app.db.mongodb import get_database
from app.schemas.items import ItemCreateRequest, ItemResponse

router = APIRouter()


def _check_store(store_id: str, current_user: dict) -> None:
    if current_user["store_id"] != store_id:
        raise HTTPException(status_code=403, detail="Not authorized for this store")


def _response(sku: dict, stock: dict | None) -> ItemResponse:
    return ItemResponse(
        id=sku["id"], store_id=sku["store_id"], name=sku["name"],
        category=sku.get("category"), unit=sku.get("unit", "pcs"),
        quantity_on_hand=stock.get("quantity_on_hand") if stock else None,
        supplier_lead_time_days=sku.get("supplier_lead_time_days", 2),
        created_at=sku["created_at"],
    )


@router.get("/{store_id}/items", response_model=list[ItemResponse])
async def list_items(
    store_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    _check_store(store_id, current_user)
    skus = await db.skus.find({"store_id": store_id}).sort("name", 1).to_list(length=None)
    stocks = await db.stock_levels.find({"store_id": store_id}).to_list(length=None)
    stock_by_sku = {stock["sku_id"]: stock for stock in stocks}
    return [_response(sku, stock_by_sku.get(sku["id"])) for sku in skus]


@router.post("/{store_id}/items", response_model=ItemResponse, status_code=201)
async def create_item(
    store_id: str,
    request: ItemCreateRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    _check_store(store_id, current_user)
    existing = await db.skus.find_one({
        "store_id": store_id,
        "name": {"$regex": f"^{re.escape(request.name)}$", "$options": "i"},
    })
    if existing:
        raise HTTPException(status_code=409, detail="An item with this name already exists")

    now = datetime.now(timezone.utc)
    sku = {
        "id": str(uuid.uuid4()), "store_id": store_id, "name": request.name,
        "category": request.category, "unit": request.unit,
        "is_perishable": False, "expiry_date": None,
        "supplier_lead_time_days": request.supplier_lead_time_days,
        "created_at": now,
    }
    await db.skus.insert_one(sku)
    stock = None
    if request.quantity_on_hand is not None:
        stock = {
            "id": str(uuid.uuid4()), "store_id": store_id, "sku_id": sku["id"],
            "quantity_on_hand": request.quantity_on_hand,
            "as_of_date": date.today().isoformat(), "updated_at": now,
        }
        await db.stock_levels.insert_one(stock)
    return _response(sku, stock)
