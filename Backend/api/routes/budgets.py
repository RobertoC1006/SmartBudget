from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from Backend.api.dependencies import get_current_user
from Backend.api.schemas import budget as budget_schema
from Backend.core import budgets as budgets_service
from Backend.db import models
from Backend.db.session import get_db


router = APIRouter(prefix="/budgets", tags=["Presupuestos"])


@router.post("/", response_model=budget_schema.BudgetRead, status_code=status.HTTP_201_CREATED)
def upsert_budget(
    payload: budget_schema.BudgetCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    budget = budgets_service.create_or_update_budget(
        db,
        user=current_user,
        amount=payload.amount,
        month=payload.month,
        year=payload.year,
        name=payload.name,
        alert_threshold=payload.alert_threshold,
    )
    return budget


@router.get("/current", response_model=budget_schema.BudgetRead)
def get_current_budget(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    budget = budgets_service.get_budget_for_period(db, current_user.id)
    if budget is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No hay presupuesto para el mes actual.")
    return budget


@router.get("/history", response_model=list[budget_schema.BudgetRead])
def list_budgets(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    budgets = (
        db.query(models.Budget)
        .filter(models.Budget.user_id == current_user.id)
        .order_by(models.Budget.year.desc(), models.Budget.month.desc())
        .all()
    )
    return budgets
