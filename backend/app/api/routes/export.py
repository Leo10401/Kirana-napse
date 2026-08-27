"""
Export routes with MongoDB (TRD §7, AppFlow §5.3).
"""

from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.db.mongodb import get_database
from app.core.security import get_current_user

router = APIRouter()


@router.get("/{store_id}/export/distributor-list")
async def generate_distributor_list(
    store_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """
    Generate shareable distributor order list for the Android share-sheet.
    """
    if current_user["store_id"] != store_id:
        raise HTTPException(status_code=403, detail="Not authorized for this store")

    store = await db.stores.find_one({"id": store_id})

    # Fetch active reorders
    cursor = db.recommendations.find({
        "store_id": store_id,
        "type": {"$in": ["reorder", "low_stock"]},
        "status": {"$in": ["pending", "edited", "ordered"]},
    }).sort("created_at", -1)
    recs = await cursor.to_list(length=100)

    items = []
    text_lines = [
        f"📋 Order List — {store.get('store_name') if store else 'My Store'}",
        f"📅 {datetime.now(timezone.utc).strftime('%d %b %Y')}",
        "─" * 30,
    ]

    for i, rec in enumerate(recs, 1):
        sku = await db.skus.find_one({"id": rec["sku_id"]})
        qty = rec.get("owner_edited_qty") if rec.get("owner_edited_qty") is not None else rec["suggested_qty"]
        sku_name = sku["name"] if sku else "Item"
        sku_unit = sku.get("unit", "pcs") if sku else "pcs"

        items.append({
            "sku_name": sku_name,
            "quantity": qty,
            "unit": sku_unit,
        })
        text_lines.append(f"{i}. {sku_name} — {int(qty) if isinstance(qty, (int, float)) and qty.is_integer() else qty} {sku_unit}")

    text_lines.append("─" * 30)
    text_lines.append(f"Total items: {len(items)}")
    text_lines.append("Sent via Kirana-Napse 🧠")

    return {
        "store_id": store_id,
        "store_name": store.get("store_name") if store else None,
        "items": items,
        "total_items": len(items),
        "formatted_text": "\n".join(text_lines),
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }
