from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from api.dependencies import get_current_user
from api.schemas import auth as auth_schema
from core import auth as auth_service
from db import models
from db.session import get_db


router = APIRouter(prefix="/auth", tags=["Autenticación"])


@router.post("/register", response_model=auth_schema.UserRead, status_code=status.HTTP_201_CREATED)
def register_user(payload: auth_schema.UserCreate, db: Session = Depends(get_db)):
    existing = auth_service.get_user_by_email(db, payload.email)
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="El correo ya está registrado.")
    user = auth_service.create_user(
        db,
        email=payload.email,
        password=payload.password,
        full_name=payload.full_name,
        monthly_income=payload.monthly_income,
        default_currency=payload.default_currency,
    )
    return user


@router.post("/login", response_model=auth_schema.Token)
def login(payload: auth_schema.UserLogin, db: Session = Depends(get_db)):
    user = auth_service.authenticate_user(db, payload.email, payload.password)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Credenciales inválidas.")
    tokens = auth_service.build_tokens(user)
    return auth_schema.Token(**tokens)


@router.get("/me", response_model=auth_schema.UserRead)
def read_profile(current_user: models.User = Depends(get_current_user)):
    return current_user
