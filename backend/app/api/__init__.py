"""
API router — aggregates all sub-routers.
"""

from fastapi import APIRouter

from app.api.routes.auth import router as auth_router
from app.api.routes.stores import router as stores_router
from app.api.routes.sales import router as sales_router
from app.api.routes.recommendations import router as recommendations_router
from app.api.routes.device import router as device_router
from app.api.routes.export import router as export_router
from app.api.routes.bills import router as bills_router

router = APIRouter()

router.include_router(auth_router, prefix="/auth", tags=["Authentication"])
router.include_router(stores_router, prefix="/stores", tags=["Stores"])
router.include_router(sales_router, prefix="/stores", tags=["Sales Data"])
router.include_router(recommendations_router, tags=["Recommendations"])
router.include_router(device_router, prefix="/stores", tags=["Device & Notifications"])
router.include_router(export_router, prefix="/stores", tags=["Export"])
router.include_router(bills_router, prefix="/stores", tags=["Bill OCR"])
router.include_router(bills_router, prefix="/bills", tags=["Bill OCR"])

