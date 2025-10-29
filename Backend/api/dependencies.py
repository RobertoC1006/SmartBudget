"""Dependencias comunes para los routers de FastAPI."""

from __future__ import annotations

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from Backend.core import auth as auth_service
from Backend.core.config import get_settings
from Backend.db import models
from Backend.db.session import get_db


oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


def get_settings_dependency():
    return get_settings()


def get_current_user(
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme),
) -> models.User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="No se pudo validar las credenciales",
        headers={"WWW-Authenticate": "Bearer"},
    )

    payload = auth_service.decode_token(token)
    if payload is None or payload.sub is None:
        raise credentials_exception

    user = auth_service.get_user_by_id(db, payload.sub)
    if user is None:
        raise credentials_exception

    return user

