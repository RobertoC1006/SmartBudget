from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from api.dependencies import get_current_user
from api.schemas import simulator as simulator_schema
from core import simulator as simulator_service
from db import models
from db.session import get_db


router = APIRouter(prefix="/simulator", tags=["Simulador"])


@router.post("/", response_model=simulator_schema.SimulatorResponse)
def run_simulation(
    payload: simulator_schema.SimulatorRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    try:
        result = simulator_service.run_simulation(
            db,
            user=current_user,
            scenario=payload.scenario,
            percentage=payload.percentage,
            custom_adjustments=payload.custom_adjustments,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    return simulator_schema.SimulatorResponse(**result.__dict__)

