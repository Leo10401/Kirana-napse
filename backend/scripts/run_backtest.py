"""
CLI Backtesting Validation Script (PRD §5.2).
Runs walk-forward backtest across stores and evaluates MAPE against the PRD target (<25%).

Usage:
  venv\\Scripts\\python.exe -m scripts.run_backtest
"""

import asyncio
from motor.motor_asyncio import AsyncIOMotorClient

from app.core.config import settings
from app.services.backtesting import run_store_backtest


async def main():
    print("=" * 70)
    print("  Kirana-Napse Demand Forecasting - Walk-Forward Backtesting Harness")
    print("=" * 70)

    client = AsyncIOMotorClient(settings.MONGODB_URL)
    db = client[settings.MONGODB_DB_NAME]

    stores_cursor = db.stores.find({})
    stores = await stores_cursor.to_list(length=10)

    if not stores:
        print("[ERROR] No stores found in MongoDB. Run `python -m app.db.seed_demo` first.")
        client.close()
        return

    for store in stores:
        store_id = store["id"]
        store_name = store.get("store_name", "Unknown Store")
        print(f"\nEvaluating Store: {store_name} ({store_id})")
        print("-" * 70)

        report = await run_store_backtest(db, store_id, holdout_days=7)

        print(f"Total SKUs Evaluated: {report['total_skus_evaluated']}")
        print(f"Overall Store MAPE:   {report['overall_average_mape']}%")
        print(f"PRD Target (<25%):    {'[PASSED] (Target Met)' if report['prd_target_achieved'] else '[REVIEW] (Needs Tuning)'}")
        print(f"Champion Models:      {report['champion_model_distribution']}")

        print("\n--- Category Breakdown ---")
        print(f"{'Category':<18} | {'SKU Count':<10} | {'Avg MAPE':<12} | {'PRD Status':<12}")
        print("-" * 60)
        for cat, stats in report["category_performance"].items():
            status_str = "PASS (<25%)" if stats["target_met_lt_25pct"] else "REVIEW"
            print(f"{cat.title():<18} | {stats['skus_count']:<10} | {stats['average_mape']}%{'':<6} | {status_str}")

        print("\n--- SKU Detail Samples ---")
        for sku_det in report["sku_details"][:6]:
            if sku_det["status"] == "success":
                name = sku_det.get("sku_name", "SKU")
                champ = sku_det["champion_model"]
                mape = sku_det["champion_mape"]
                actual = sku_det["actual_demand"]
                print(f" • {name:<35} | Model: {champ:<14} | Actual: {actual:<5} | MAPE: {mape}%")

    print("\n" + "=" * 70)
    print("  Backtesting Run Completed.")
    print("=" * 70)
    client.close()


if __name__ == "__main__":
    asyncio.run(main())
