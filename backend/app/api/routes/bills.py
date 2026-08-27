"""
Bills / OCR photo routes with MongoDB (TRD §5.1, §7 Table 5).
"""

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.db.mongodb import get_database
from app.services.ocr import create_ocr_job, get_ocr_job
from app.core.security import get_current_user

router = APIRouter()


@router.post("/{store_id}/bills/photo", status_code=202)
async def upload_bill_photo(
    store_id: str,
    file: UploadFile = File(...),
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """
    Submit a photographed bill for OCR processing (async: submit + poll).
    """
    if current_user["store_id"] != store_id:
        raise HTTPException(status_code=403, detail="Not authorized for this store")

    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Empty file uploaded")

    job_id = create_ocr_job(store_id, file.filename or "bill.jpg", contents)

    return {
        "job_id": job_id,
        "store_id": store_id,
        "status": "processing",
        "poll_url": f"/api/v1/bills/jobs/{job_id}",
        "message": "Bill image submitted for OCR parsing",
    }


@router.get("/jobs/{job_id}")
async def get_bill_ocr_job(
    job_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Poll / receive OCR parse result for owner confirmation (TRD §7 Table 5).
    """
    job = get_ocr_job(job_id)
    if not job:
        raise HTTPException(status_code=404, detail="OCR job not found")

    if job["store_id"] != current_user["store_id"]:
        raise HTTPException(status_code=403, detail="Not authorized for this job")

    return job
