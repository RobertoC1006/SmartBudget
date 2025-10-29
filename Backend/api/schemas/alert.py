from __future__ import annotations

import datetime as dt

from pydantic import BaseModel

from Backend.core.enums import AlertSeverity, AlertType


class AlertRead(BaseModel):
    id: str
    alert_type: AlertType
    severity: AlertSeverity
    title: str
    message: str
    acknowledged: bool
    created_at: dt.datetime

    class Config:
        from_attributes = True

