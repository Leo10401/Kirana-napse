"""
Recommendation routes with MongoDB (TRD §5.3, §5.7, §7).
"""

import uuid
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.db.mongodb import get_database
from app.schemas.recommendation import (
    RecommendationResponse,
    RecommendationUpdateRequest,
    TodayRecommendationsResponse,
    FeedbackFlagRequest,
    FeedbackFlagResponse,
)
from app.core.security import get_current_user

router = APIRouter()


@router.get("/stores/{store_id}/recommendations/today", response_model=TodayRecommendationsResponse)
async def get_today_recommendations(
    store_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """
    Fetch current reorder/low-stock/overstock recommendations for a store.
    """
    if current_user["store_id"] != store_id:
        raise HTTPException(status_code=403, detail="Not authorized for this store")

    latest_run = await db.forecast_runs.find_one(
        {"store_id": store_id}, sort=[("created_at", -1)]
    )
    query = {"store_id": store_id}
    if latest_run and latest_run.get("batch_id"):
        query["batch_id"] = latest_run["batch_id"]
    cursor = db.recommendations.find(query).sort("created_at", -1).limit(200)
    recent_recs = await cursor.to_list(length=200)
    # Re-running the forecast can leave older recommendations for the same
    # product. Show only its newest recommendation in the daily view.
    recs = []
    seen_skus = set()
    for rec in recent_recs:
        if rec["sku_id"] not in seen_skus:
            seen_skus.add(rec["sku_id"])
            recs.append(rec)

    responses = []
    for rec in recs:
        sku = await db.skus.find_one({"id": rec["sku_id"]})
        cold_start = False
        if rec.get("forecast_id"):
            fr = await db.forecast_runs.find_one({"id": rec["forecast_id"]})
            cold_start = fr.get("cold_start_flag", False) if fr else False

        responses.append(RecommendationResponse(
            id=rec["id"],
            store_id=rec["store_id"],
            sku_id=rec["sku_id"],
            sku_name=sku["name"] if sku else None,
            sku_category=sku.get("category") if sku else None,
            sku_unit=sku.get("unit", "pcs") if sku else None,
            type=rec["type"],
            suggested_qty=rec["suggested_qty"],
            owner_edited_qty=rec.get("owner_edited_qty"),
            reason_text=rec.get("reason_text"),
            reason_text_hi=rec.get("reason_text_hi"),
            status=rec.get("status", "pending"),
            cold_start=cold_start,
            created_at=rec.get("created_at", datetime.now(timezone.utc)),
        ))

    reorder = sum(1 for r in responses if r.type == "reorder")
    low_stock = sum(1 for r in responses if r.type == "low_stock")
    overstock = sum(1 for r in responses if r.type == "overstock")
    expiry = sum(1 for r in responses if r.type == "expiry_risk")

    return TodayRecommendationsResponse(
        store_id=store_id,
        date=datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        reorder_count=reorder,
        overstock_count=overstock,
        expiry_risk_count=expiry,
        low_stock_count=low_stock,
        recommendations=responses,
        last_updated=datetime.now(timezone.utc),
    )


@router.patch("/recommendations/{rec_id}", response_model=RecommendationResponse)
async def update_recommendation(
    rec_id: str,
    request: RecommendationUpdateRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """Owner edits a recommendation — changes qty, marks ordered, or dismisses."""
    rec = await db.recommendations.find_one({"id": rec_id})
    if not rec:
        raise HTTPException(status_code=404, detail="Recommendation not found")
    if rec["store_id"] != current_user["store_id"]:
        raise HTTPException(status_code=403, detail="Not authorized")

    update_fields = {"status": request.status, "updated_at": datetime.now(timezone.utc)}
    if request.owner_edited_qty is not None:
        update_fields["owner_edited_qty"] = request.owner_edited_qty

    await db.recommendations.update_one({"id": rec_id}, {"$set": update_fields})
    updated_rec = await db.recommendations.find_one({"id": rec_id})
    sku = await db.skus.find_one({"id": updated_rec["sku_id"]})

    return RecommendationResponse(
        id=updated_rec["id"],
        store_id=updated_rec["store_id"],
        sku_id=updated_rec["sku_id"],
        sku_name=sku["name"] if sku else None,
        sku_category=sku.get("category") if sku else None,
        sku_unit=sku.get("unit", "pcs") if sku else None,
        type=updated_rec["type"],
        suggested_qty=updated_rec["suggested_qty"],
        owner_edited_qty=updated_rec.get("owner_edited_qty"),
        reason_text=updated_rec.get("reason_text"),
        reason_text_hi=updated_rec.get("reason_text_hi"),
        status=updated_rec.get("status", "pending"),
        cold_start=False,
        created_at=updated_rec.get("created_at", datetime.now(timezone.utc)),
    )


@router.post("/recommendations/{rec_id}/flag", response_model=FeedbackFlagResponse, status_code=201)
async def flag_recommendation(
    rec_id: str,
    request: FeedbackFlagRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """Submit a 'forecast was wrong' feedback flag with reason code."""
    rec = await db.recommendations.find_one({"id": rec_id})
    if not rec:
        raise HTTPException(status_code=404, detail="Recommendation not found")
    if rec["store_id"] != current_user["store_id"]:
        raise HTTPException(status_code=403, detail="Not authorized")

    flag_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    flag_doc = {
        "id": flag_id,
        "recommendation_id": rec_id,
        "reason_code": request.reason_code,
        "free_text": request.free_text,
        "submitted_at": now,
    }
    await db.feedback_flags.insert_one(flag_doc)

    return FeedbackFlagResponse(
        id=flag_id,
        recommendation_id=rec_id,
        reason_code=request.reason_code,
        free_text=request.free_text,
        submitted_at=now,
    )
