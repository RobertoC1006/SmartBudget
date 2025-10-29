from __future__ import annotations

from typing import Optional

from pydantic import BaseModel, Field

from Backend.core.enums import SimulationScenario


class SimulatorRequest(BaseModel):
    scenario: SimulationScenario
    percentage: Optional[float] = Field(default=None, ge=0, le=100)
    custom_adjustments: Optional[dict[str, float]] = None


class SimulatorResponse(BaseModel):
    projected_score: int
    band: str
    remaining_budget: float
    adjustments: dict[str, float]
    narrative: str

