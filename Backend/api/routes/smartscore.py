from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from Backend.api.dependencies import get_current_user
from Backend.api.schemas import smartscore as smartscore_schema
from Backend.core import alerts as alerts_service
from Backend.core import smartscore as smartscore_service
from Backend.db import models
from Backend.db.session import get_db


router = APIRouter(prefix="/smartscore", tags=["SmartScore"])


@router.post("/recalculate", response_model=smartscore_schema.SmartScoreRead)
def recalculate_smartscore(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    snapshot = smartscore_service.calculate_smartscore(db, current_user)
    alerts_service.generate_alerts_from_score(db, snapshot)
    return snapshot


@router.get("/history", response_model=list[smartscore_schema.SmartScoreRead])
def list_history(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    snapshots = (
        db.query(models.SmartScoreSnapshot)
        .filter(models.SmartScoreSnapshot.user_id == current_user.id)
        .order_by(models.SmartScoreSnapshot.created_at.desc())
        .all()
    )
    return snapshots
