from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from Backend.api.dependencies import get_current_user
from Backend.api.schemas import goal as goal_schema
from Backend.core import goals as goals_service
from Backend.db import models
from Backend.db.session import get_db


router = APIRouter(prefix="/goals", tags=["Metas"])


@router.post("/", response_model=goal_schema.GoalRead, status_code=status.HTTP_201_CREATED)
def create_goal(
    payload: goal_schema.GoalCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    goal = goals_service.create_goal(
        db,
        user=current_user,
        name=payload.name,
        description=payload.description,
        target_amount=payload.target_amount,
        target_date=payload.target_date,
    )
    return goal


@router.get("/", response_model=list[goal_schema.GoalRead])
def list_goals(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    goals = goals_service.list_goals(db, current_user.id)
    return list(goals)


@router.post("/{goal_id}/progress", response_model=goal_schema.GoalRead)
def update_goal_progress(
    goal_id: str,
    amount: float,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    goal = goals_service.get_goal(db, goal_id, current_user.id)
    if goal is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Meta no encontrada.")
    updated = goals_service.update_progress(db, goal, amount)
    return updated


@router.get("/suggestions", response_model=list[str])
def suggest_goals(current_user: models.User = Depends(get_current_user)):
    return goals_service.recommend_goals(current_user)

