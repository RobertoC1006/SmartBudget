from __future__ import annotations

import datetime as dt

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from Backend.api.dependencies import get_current_user
from Backend.api.schemas import expense as expense_schema
from Backend.core import expenses as expenses_service
from Backend.core.enums import ExpenseCategory, ExpenseSource
from Backend.db import models
from Backend.db.session import get_db


router = APIRouter(prefix="/expenses", tags=["Gastos"])


@router.post("/", response_model=expense_schema.ExpenseRead, status_code=status.HTTP_201_CREATED)
def create_manual_expense(
    payload: expense_schema.ExpenseCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    expense_date = payload.expense_date or dt.date.today()
    expense = expenses_service.create_expense(
        db,
        user=current_user,
        description=payload.description,
        amount=payload.amount,
        category=payload.category,
        expense_date=expense_date,
        source=ExpenseSource.MANUAL,
        currency=payload.currency or current_user.default_currency,
    )
    return expense


@router.get("/", response_model=list[expense_schema.ExpenseRead])
def list_my_expenses(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
    category: ExpenseCategory | None = None,
):
    expenses = expenses_service.list_expenses(
        db,
        user_id=current_user.id,
        category=category,
    )
    return list(expenses)


@router.post("/upload", response_model=expense_schema.OCRExpenseResponse)
async def upload_receipt(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    data = await file.read()
    if not data:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="El archivo proporcionado está vacío.")
    try:
        expense, ocr_result, structured = expenses_service.create_expense_from_ocr(
            db,
            user=current_user,
            filename=file.filename or "comprobante",
            data=data,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    except RuntimeError as exc:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(exc)) from exc

    return expense_schema.OCRExpenseResponse(
        expense=expense,
        ocr_confidence=ocr_result.confidence,
        structured_data=structured,
    )
