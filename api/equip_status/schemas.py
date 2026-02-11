from datetime import datetime

from pydantic import BaseModel, ConfigDict


class EquipStatusBase(BaseModel):
    """Represents equip_status intervals (not raw events)."""

    equip_id: int
    status_code: str | None = None
    start_time: datetime
    end_time: datetime | None = None


class EquipStatusCreate(EquipStatusBase):
    pass


class EquipStatusRead(EquipStatusBase):
    id: int
    model_config = ConfigDict(from_attributes=True)
