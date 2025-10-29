from __future__ import annotations

import datetime as dt
from typing import Any

from pydantic import BaseModel

from Backend.core.enums import SmartScoreBand


class SmartScoreRead(BaseModel):
    id: str
    score: int
    band: SmartScoreBand
    summary: str
    drivers: dict[str, Any]
    created_at: dt.datetime

    class Config:
        from_attributes = True

