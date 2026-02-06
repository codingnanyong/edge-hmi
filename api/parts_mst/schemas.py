from datetime import datetime

from pydantic import BaseModel, ConfigDict


class PartsMstBase(BaseModel):
    equip_id: int
    part_name: str
    spec_lifespan_hours: float | None = None
    current_usage_hours: float = 0
    last_replacement_date: datetime | None = None


class PartsMstCreate(PartsMstBase):
    pass


class PartsMstUpdate(BaseModel):
    equip_id: int | None = None
    part_name: str | None = None
    spec_lifespan_hours: float | None = None
    current_usage_hours: float | None = None
    last_replacement_date: datetime | None = None


class PartsMstRead(PartsMstBase):
    id: int
    model_config = ConfigDict(from_attributes=True)
