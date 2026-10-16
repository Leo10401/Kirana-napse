"""
Demo Store Seeder for MongoDB / MongoDB Atlas (PRD §5.1, TRD §5.2).
Creates demo user "Ramesh Kumar" (phone: +919876543210, password: password123),
seeds realistic kirana SKUs, sales records, and runs the forecasting engine.
"""

import asyncio
import uuid
from datetime import date, datetime, timedelta, timezone
from motor.motor_asyncio import AsyncIOMotorClient

from app.core.config import settings
from app.core.security import hash_password
from app.services.forecasting import run_forecast_for_store
from app.db.init_db import seed_festivals

DEMO_SKUS = [
    {"name": "Amul Butter 500g", "category": "dairy", "unit": "pcs", "is_perishable": True, "lead_time": 2, "stock": 4.0, "avg_daily_sales": 8.0},
    {"name": "Aashirvaad Shudh Chakki Atta 5kg", "category": "grocery", "unit": "pcs", "is_perishable": False, "lead_time": 3, "stock": 2.0, "avg_daily_sales": 6.0},
    {"name": "Tata Tea Premium 500g", "category": "beverages", "unit": "pcs", "is_perishable": False, "lead_time": 2, "stock": 17.0, "avg_daily_sales": 4.0},
    {"name": "Fortune Sunlite Sunflower Oil 1L", "category": "grocery", "unit": "ltr", "is_perishable": False, "lead_time": 2, "stock": 5.0, "avg_daily_sales": 10.0},
    {"name": "Maggi 2-Minute Noodles 70g", "category": "snacks", "unit": "pcs", "is_perishable": False, "lead_time": 1, "stock": 3.0, "avg_daily_sales": 15.0},
    {"name": "Dettol Original Soap 125g (Pack of 3)", "category": "personal care", "unit": "pack", "is_perishable": False, "lead_time": 2, "stock": 75.0, "avg_daily_sales": 1.5},
    {"name": "Mother Dairy Full Cream Milk 500ml", "category": "dairy", "unit": "pcs", "is_perishable": True, "lead_time": 1, "stock": 12.0, "avg_daily_sales": 2.5, "days_to_expiry": 2},
    {"name": "Parle-G Gold Biscuits 100g", "category": "snacks", "unit": "pcs", "is_perishable": False, "lead_time": 1, "stock": 100.0, "avg_daily_sales": 2.0},
    {"name": "Surf Excel Easy Wash Detergent 1kg", "category": "personal care", "unit": "pcs", "is_perishable": False, "lead_time": 2, "stock": 13.0, "avg_daily_sales": 3.0},
    {"name": "Cadbury Dairy Milk Silk 60g", "category": "snacks", "unit": "pcs", "is_perishable": True, "lead_time": 2, "stock": 20.0, "avg_daily_sales": 3.0, "days_to_expiry": 4},
]

DEMO_PRICES = [285, 315, 245, 160, 14, 145, 32, 10, 125, 80]


async def seed_demo():
    """Seed demo user, store, inventory and recommendations into MongoDB."""
    await seed_festivals()

    client = AsyncIOMotorClient(settings.MONGODB_URL)
    db = client[settings.MONGODB_DB_NAME]

    demo_phone = "+919876543210"
    user = await db.users.find_one({"phone": demo_phone})
    now = datetime.now(timezone.utc)

    if not user:
        user_id = str(uuid.uuid4())
        store_id = str(uuid.uuid4())

        user_doc = {
            "id": user_id,
            "phone": demo_phone,
            "password_hash": hash_password("password123"),
            "name": "Ramesh Kumar",
            "is_active": True,
            "created_at": now,
            "updated_at": now,
        }
        await db.users.insert_one(user_doc)

        store_doc = {
            "id": store_id,
            "owner_id": user_id,
            "owner_name": "Ramesh Kumar",
            "store_name": "Ramesh General Store",
            "category": "General Store",
            "sku_count_estimate": 500,
            "city": "Lucknow",
            "region": "Uttar Pradesh",
            "language_pref": "hi",
            "tracking_method": "billing_app",
            "onboarding_source": "organic",
            "status": "active",
            "notification_enabled": True,
            "created_at": now,
            "updated_at": now,
        }
        await db.stores.insert_one(store_doc)
    else:
        user_id = user["id"]
        store = await db.stores.find_one({"owner_id": user_id})
        store_id = store["id"]

    today = date.today()

    # Refresh only the known demo products. The script is safe to rerun.
    for index, sku_data in enumerate(DEMO_SKUS):
        existing_sku = await db.skus.find_one({"store_id": store_id, "name": sku_data["name"]})
        expiry_date_str = (today + timedelta(days=sku_data.get("days_to_expiry", 180))).isoformat() if sku_data["is_perishable"] else None
        if not existing_sku:
            sku_id = str(uuid.uuid4())
            sku_doc = {
                "id": sku_id,
                "store_id": store_id,
                "name": sku_data["name"],
                "category": sku_data["category"],
                "unit": sku_data["unit"],
                "is_perishable": sku_data["is_perishable"],
                "expiry_date": expiry_date_str,
                "supplier_lead_time_days": sku_data["lead_time"],
                "created_at": now,
            }
            await db.skus.insert_one(sku_doc)
        else:
            sku_id = existing_sku["id"]
            await db.skus.update_one({"id": sku_id}, {"$set": {
                "category": sku_data["category"], "unit": sku_data["unit"],
                "is_perishable": sku_data["is_perishable"],
                "expiry_date": expiry_date_str,
                "supplier_lead_time_days": sku_data["lead_time"],
            }})

        await db.stock_levels.update_one(
            {"store_id": store_id, "sku_id": sku_id},
            {"$set": {"quantity_on_hand": sku_data["stock"],
                      "as_of_date": today.isoformat(), "updated_at": now},
             "$setOnInsert": {"id": str(uuid.uuid4()), "store_id": store_id, "sku_id": sku_id}},
            upsert=True,
        )

        # Remove records created by the old demo seeder, identified by its
        # shared SKU creation timestamp. Manually entered sales are retained.
        if existing_sku:
            await db.sales_records.delete_many({
                "store_id": store_id, "sku_id": sku_id,
                "created_at": existing_sku["created_at"],
                "revenue": {"$exists": True},
            })
        await db.sales_records.delete_many({
            "store_id": store_id, "sku_id": sku_id, "demo_seed": True,
        })

        sales_docs = []
        for days_ago in range(21, 0, -1):
            sales_date = today - timedelta(days=days_ago)
            weekend = sales_date.weekday() >= 5
            variation = (1.22 if weekend else 1.0) * (0.87 if days_ago % 5 == 0 else 1.0)
            qty_sold = round(sku_data["avg_daily_sales"] * variation, 1)
            sales_docs.append({
                "id": str(uuid.uuid4()), "store_id": store_id, "sku_id": sku_id,
                "date": sales_date.isoformat(), "quantity_sold": qty_sold,
                "revenue": round(qty_sold * DEMO_PRICES[index], 2),
                "source": "manual", "confidence": 1.0,
                "created_at": now, "demo_seed": True,
            })
        await db.sales_records.insert_many(sales_docs)

    # Reset the demo's old recommendation runs to prevent repeated alerts.
    await db.recommendations.delete_many({"store_id": store_id})
    await db.forecast_runs.delete_many({"store_id": store_id})
    res = await run_forecast_for_store(db, store_id, region="National")
    print(f"[OK] Demo store seeded for Ramesh Kumar ({demo_phone})")
    print(f"[OK] {len(DEMO_SKUS)} items, {len(DEMO_SKUS) * 21} recent sample sales.")
    print(f"[OK] Forecasting generated: {res['recommendations_generated']} recommendations.")
    client.close()


if __name__ == "__main__":
    asyncio.run(seed_demo())
