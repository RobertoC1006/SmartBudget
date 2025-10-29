"""Servicios relacionados a autenticación y gestión de usuarios."""

from __future__ import annotations

import datetime as dt
from typing import Optional

from jose import JWTError, jwt
from pydantic import BaseModel
from sqlalchemy.orm import Session

from Backend.core.config import get_settings
from Backend.core.security import create_access_token, get_password_hash, verify_password
from Backend.db import models


class TokenPayload(BaseModel):
    sub: str
    exp: int


def get_user_by_email(db: Session, email: str) -> Optional[models.User]:
    return db.query(models.User).filter(models.User.email == email).first()


def get_user_by_id(db: Session, user_id: str) -> Optional[models.User]:
    return db.query(models.User).filter(models.User.id == user_id).first()


def create_user(
    db: Session,
    *,
    email: str,
    password: str,
    full_name: str,
    monthly_income: float | None = None,
    default_currency: str | None = None,
) -> models.User:
    settings = get_settings()
    user = models.User(
        email=email.lower(),
        hashed_password=get_password_hash(password),
        full_name=full_name,
        default_currency=default_currency or settings.default_currency,
        monthly_income=monthly_income,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def authenticate_user(db: Session, email: str, password: str) -> Optional[models.User]:
    user = get_user_by_email(db, email=email.lower())
    if user is None:
        return None
    if not verify_password(password, user.hashed_password):
        return None
    return user


def build_tokens(user: models.User) -> dict[str, str]:
    settings = get_settings()
    now = dt.datetime.utcnow()
    access_token = create_access_token(
        data={"sub": user.id, "iat": int(now.timestamp())},
        expires_minutes=settings.access_token_expire_minutes,
    )
    refresh_token = create_access_token(
        data={"sub": user.id, "iat": int(now.timestamp()), "scope": "refresh"},
        expires_minutes=settings.refresh_token_expire_minutes,
    )
    return {"access_token": access_token, "refresh_token": refresh_token}


def decode_token(token: str) -> Optional[TokenPayload]:
    settings = get_settings()
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.jwt_algorithm])
        return TokenPayload(**payload)
    except JWTError:
        return None

