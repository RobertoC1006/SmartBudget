from __future__ import annotations

import datetime as dt
from typing import Optional

from pydantic import BaseModel, EmailStr, Field


class UserBase(BaseModel):
    email: EmailStr
    full_name: str = Field(min_length=3, max_length=255)


class UserCreate(UserBase):
    password: str = Field(min_length=8, max_length=128)
    monthly_income: Optional[float] = None
    default_currency: Optional[str] = Field(default=None, max_length=3)


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserRead(UserBase):
    id: str
    default_currency: str
    monthly_income: Optional[float] = None
    is_active: bool
    created_at: dt.datetime

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenPayload(BaseModel):
    sub: str
    exp: int
    scope: Optional[str] = None

