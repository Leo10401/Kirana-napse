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
    {"name": "Tata Tea Premium 500g", "category": "beverages", "unit": "pcs", "is_perishable": False, "lead_time": 2, "stock": 18.0, "avg_daily_sales": 4.0},
    {"name": "Fortune Sunlite Sunflower Oil 1L", "category": "grocery", "unit": "ltr", "is_perishable": False, "lead_time": 2, "stock": 5.0, "avg_daily_sales": 10.0},
    {"name": "Maggi 2-Minute Noodles 70g", "category": "snacks", "unit": "pcs", "is_perishable": False, "lead_time": 1, "stock": 3.0, "avg_daily_sales": 15.0},
    {"name": "Dettol Original Soap 125g (Pack of 3)", "category": "personal care", "unit": "pack", "is_perishable": False, "lead_time": 2, "stock": 35.0, "avg_daily_sales": 1.5},
    {"name": "Mother Dairy Full Cream Milk 500ml", "category": "dairy", "unit": "pcs", "is_perishable": True, "lead_time": 1, "stock": 6.0, "avg_daily_sales": 25.0, "days_to_expiry": 2},
    {"name": "Parle-G Gold Biscuits 100g", "category": "snacks", "unit": "pcs", "is_perishable": False, "lead_time": 1, "stock": 80.0, "avg_daily_sales": 2.0},
    {"name": "Surf Excel Easy Wash Detergent 1kg", "category": "personal care", "unit": "pcs", "is_perishable": False, "lead_time": 2, "stock": 14.0, "avg_daily_sales": 3.0},
    {"name": "Cadbury Dairy Milk Silk 60g", "category": "snacks", "unit": "pcs", "is_perishable": True, "lead_time": 2, "stock": 4.0, "avg_daily_sales": 5.0, "days_to_expiry": 4},
]


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

    # Seed SKUs, stock levels, and 14 days of sales
    for sku_data in DEMO_SKUS:
        existing_sku = await db.skus.find_one({"store_id": store_id, "name": sku_data["name"]})
        if not existing_sku:
            sku_id = str(uuid.uuid4())
            expiry_date_str = (today + timedelta(days=sku_data.get("days_to_expiry", 180))).isoformat() if sku_data["is_perishable"] else None

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

            # Stock level
            stock_doc = {
                "id": str(uuid.uuid4()),
                "store_id": store_id,
                "sku_id": sku_id,
                "as_of_date": today.isoformat(),
                "quantity_on_hand": sku_data["stock"],
                "updated_at": now,
            }
            await db.stock_levels.insert_one(stock_doc)

            # 14 days of sales history
            avg_sales = sku_data["avg_daily_sales"]
            sales_docs = []
            for days_ago in range(14, 0, -1):
                sales_date = today - timedelta(days=days_ago)
                variation = 0.8 if (days_ago % 3 == 0) else (1.3 if days_ago % 7 == 0 else 1.0)
                qty_sold = round(avg_sales * variation, 1)

                sales_docs.append({
                    "id": str(uuid.uuid4()),
                    "store_id": store_id,
                    "sku_id": sku_id,
                    "date": sales_date.isoformat(),
                    "quantity_sold": qty_sold,
                    "revenue": qty_sold * 50.0,
                    "source": "manual",
                    "confidence": 1.0,
                    "created_at": now,
                })
            if sales_docs:
                await db.sales_records.insert_many(sales_docs)

    # Run forecasting engine
    res = await run_forecast_for_store(db, store_id, region="National")
    print(f"[OK] Demo store seeded for Ramesh Kumar ({demo_phone})")
    print(f"[OK] Forecasting generated: {res['recommendations_generated']} recommendations.")
    client.close()


if __name__ == "__main__":
    asyncio.run(seed_demo())
