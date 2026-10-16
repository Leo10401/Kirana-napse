"""Catalog items are created explicitly and sales refer to existing IDs."""

import asyncio
import unittest
from datetime import date
from types import SimpleNamespace
from unittest.mock import AsyncMock

from fastapi import HTTPException

from app.api.routes.items import create_item
from app.api.routes.sales import add_sales_entry, bulk_import_sales, update_stock_level
from app.schemas.items import ItemCreateRequest
from app.schemas.sales import SalesBulkImportRequest, SalesEntryRequest, StockUpdateRequest


class ItemSalesFlowTests(unittest.TestCase):
    def setUp(self):
        self.db = SimpleNamespace(
            skus=SimpleNamespace(find_one=AsyncMock(), insert_one=AsyncMock()),
            stock_levels=SimpleNamespace(insert_one=AsyncMock(), update_one=AsyncMock()),
            sales_records=SimpleNamespace(insert_one=AsyncMock(), insert_many=AsyncMock()),
        )
        self.user = {"store_id": "store-1"}

    def test_create_item_then_record_sale(self):
        self.db.skus.find_one.side_effect = [None, {
            "id": "item-1", "store_id": "store-1", "name": "Rice",
        }]
        item = asyncio.run(create_item("store-1", ItemCreateRequest(
            name=" Rice ", quantity_on_hand=12), self.db, self.user))
        self.assertEqual(item.name, "Rice")
        self.assertEqual(item.quantity_on_hand, 12)
        self.assertEqual(self.db.skus.insert_one.await_count, 1)

        sale = asyncio.run(add_sales_entry("store-1", SalesEntryRequest(
            sku_id="item-1", date=date.today(), quantity_sold=2), self.db, self.user))
        self.assertEqual(sale.sku_id, "item-1")
        self.assertEqual(sale.sku_name, "Rice")
        self.assertEqual(self.db.skus.insert_one.await_count, 1)

    def test_unknown_item_cannot_create_sale_or_stock(self):
        self.db.skus.find_one.return_value = None
        with self.assertRaises(HTTPException) as sale_error:
            asyncio.run(add_sales_entry("store-1", SalesEntryRequest(
                sku_id="missing", date=date.today(), quantity_sold=2), self.db, self.user))
        self.assertEqual(sale_error.exception.status_code, 404)
        self.db.sales_records.insert_one.assert_not_awaited()

        with self.assertRaises(HTTPException) as stock_error:
            asyncio.run(update_stock_level("store-1", StockUpdateRequest(
                sku_id="missing", quantity_on_hand=4), self.db, self.user))
        self.assertEqual(stock_error.exception.status_code, 404)
        self.db.stock_levels.update_one.assert_not_awaited()

    def test_import_validates_every_item_before_inserting(self):
        self.db.skus.find_one.side_effect = lambda query: (
            {"id": "item-1", "store_id": "store-1"}
            if query["id"] == "item-1" else None
        )
        request = SalesBulkImportRequest(records=[
            SalesEntryRequest(sku_id="item-1", date=date.today(), quantity_sold=1),
            SalesEntryRequest(sku_id="missing", date=date.today(), quantity_sold=1),
        ])
        with self.assertRaises(HTTPException) as error:
            asyncio.run(bulk_import_sales("store-1", request, self.db, self.user))
        self.assertEqual(error.exception.status_code, 404)
        self.db.sales_records.insert_many.assert_not_awaited()

    def test_duplicate_item_name_is_rejected(self):
        self.db.skus.find_one.return_value = {"id": "item-1"}
        with self.assertRaises(HTTPException) as error:
            asyncio.run(create_item("store-1", ItemCreateRequest(name="rice"), self.db, self.user))
        self.assertEqual(error.exception.status_code, 409)
        self.db.skus.insert_one.assert_not_awaited()


if __name__ == "__main__":
    unittest.main()
