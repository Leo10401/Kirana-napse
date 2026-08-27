"""
CLI Model Training Script.
Runs nightly batch training pipeline to fit and persist champion model artifacts per SKU.
"""

import asyncio
from motor.motor_asyncio import AsyncIOMotorClient

from app.core.config import settings
from app.services.model_training import train_store_models


async def main():
    print("=" * 70)
    print("  Kirana-Napse Model Training & Artifact Persistence Pipeline")
    print("=" * 70)

    client = AsyncIOMotorClient(settings.MONGODB_URL)
    db = client[settings.MONGODB_DB_NAME]

    stores_cursor = db.stores.find({})
    stores = await stores_cursor.to_list(length=10)

    for store in stores:
        store_id = store["id"]
        store_name = store.get("store_name", "Unknown Store")
        print(f"\nTraining Models for Store: {store_name} ({store_id})")
        res = await train_store_models(db, store_id)
        print(f"Total SKUs: {res['total_skus']}")
        print(f"Models Trained & Persisted: {res['trained_count']}")
        print(f"Model Distribution: {res['model_distribution']}")

    print("\n[OK] Model training completed successfully.")
    client.close()


if __name__ == "__main__":
    asyncio.run(main())
