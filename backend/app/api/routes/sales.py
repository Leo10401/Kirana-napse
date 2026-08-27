"""
Sales routes — manual entry, bulk import, stock updates with MongoDB (TRD §5.1, §7).
"""

import uuid
from datetime import date, datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.db.mongodb import get_database
from app.schemas.sales import (
    SalesEntryRequest,
    SalesBulkImportRequest,
    SalesRecordResponse,
    StockUpdateRequest,
)
from app.core.security import get_current_user

router = APIRouter()


async def _get_or_create_sku(
    db: AsyncIOMotorDatabase, store_id: str, name: str, category: str | None, unit: str
) -> dict:
    """Find an existing SKU by name or create a new one."""
    sku = await db.skus.find_one({"store_id": store_id, "name": name})
    if not sku:
        sku_id = str(uuid.uuid4())
        sku = {
            "id": sku_id,
            "store_id": store_id,
            "name": name,
            "category": category,
            "unit": unit,
            "is_perishable": False,
            "expiry_date": None,
            "supplier_lead_time_days": 2,
            "created_at": datetime.now(timezone.utc),
        }
        await db.skus.insert_one(sku)
    return sku


@router.post("/{store_id}/sales", response_model=SalesRecordResponse, status_code=201)
async def add_sales_entry(
    store_id: str,
    request: SalesEntryRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """Add a single sales record (manual entry or OCR-confirmed)."""
    if current_user["store_id"] != store_id:
        raise HTTPException(status_code=403, detail="Not authorized for this store")

    sku = await _get_or_create_sku(
        db, store_id, request.sku_name, request.sku_category, request.unit
    )

    record_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    record = {
        "id": record_id,
        "store_id": store_id,
        "sku_id": sku["id"],
        "date": request.date.isoformat(),
        "quantity_sold": request.quantity_sold,
        "revenue": request.revenue,
        "source": request.source,
        "confidence": 1.0,
        "created_at": now,
    }
    await db.sales_records.insert_one(record)

    return SalesRecordResponse(
        id=record_id,
        store_id=store_id,
        sku_id=sku["id"],
        sku_name=sku["name"],
        date=request.date,
        quantity_sold=request.quantity_sold,
        revenue=request.revenue,
        source=request.source,
        confidence=1.0,
        created_at=now,
    )


@router.post("/{store_id}/sales/import", status_code=201)
async def bulk_import_sales(
    store_id: str,
    request: SalesBulkImportRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """Bulk import sales records (CSV/API import)."""
    if current_user["store_id"] != store_id:
        raise HTTPException(status_code=403, detail="Not authorized for this store")

    now = datetime.now(timezone.utc)
    records_to_insert = []

    for entry in request.records:
        sku = await _get_or_create_sku(
            db, store_id, entry.sku_name, entry.sku_category, entry.unit
        )
        record = {
            "id": str(uuid.uuid4()),
            "store_id": store_id,
            "sku_id": sku["id"],
            "date": entry.date.isoformat(),
            "quantity_sold": entry.quantity_sold,
            "revenue": entry.revenue,
            "source": entry.source,
            "confidence": 1.0,
            "created_at": now,
        }
        records_to_insert.append(record)

    if records_to_insert:
        await db.sales_records.insert_many(records_to_insert)

    return {"imported": len(records_to_insert), "store_id": store_id}


@router.get("/{store_id}/sales", response_model=list[SalesRecordResponse])
async def get_sales_history(
    store_id: str,
    start_date: date | None = None,
    end_date: date | None = None,
    sku_id: str | None = None,
    limit: int = 100,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """Get sales history for a store, optionally filtered by date and SKU."""
    if current_user["store_id"] != store_id:
        raise HTTPException(status_code=403, detail="Not authorized for this store")

    query: dict = {"store_id": store_id}
    if start_date:
        query["date"] = {"$gte": start_date.isoformat()}
    if end_date:
        query.setdefault("date", {})["$lte"] = end_date.isoformat()
    if sku_id:
        query["sku_id"] = sku_id

    cursor = db.sales_records.find(query).sort("date", -1).limit(limit)
    records = await cursor.to_list(length=limit)

    responses = []
    for r in records:
        sku = await db.skus.find_one({"id": r["sku_id"]})
        d_val = r["date"]
        parsed_date = date.fromisoformat(d_val) if isinstance(d_val, str) else d_val
        responses.append(SalesRecordResponse(
            id=r["id"],
            store_id=r["store_id"],
            sku_id=r["sku_id"],
            sku_name=sku["name"] if sku else None,
            date=parsed_date,
            quantity_sold=r["quantity_sold"],
            revenue=r.get("revenue"),
            source=r.get("source", "manual"),
            confidence=r.get("confidence", 1.0),
            created_at=r.get("created_at", datetime.now(timezone.utc)),
        ))

    return responses


@router.post("/{store_id}/stock", status_code=200)
async def update_stock_level(
    store_id: str,
    request: StockUpdateRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """Update current stock level for a SKU."""
    if current_user["store_id"] != store_id:
        raise HTTPException(status_code=403, detail="Not authorized for this store")

    today_str = date.today().isoformat()
    now = datetime.now(timezone.utc)

    await db.stock_levels.update_one(
        {"store_id": store_id, "sku_id": request.sku_id},
        {
            "$set": {
                "quantity_on_hand": request.quantity_on_hand,
                "as_of_date": today_str,
                "updated_at": now,
            },
            "$setOnInsert": {
                "id": str(uuid.uuid4()),
                "store_id": store_id,
                "sku_id": request.sku_id,
            }
        },
        upsert=True,
    )

    return {"status": "updated", "sku_id": request.sku_id, "quantity_on_hand": request.quantity_on_hand}
