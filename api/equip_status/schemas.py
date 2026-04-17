from datetime import datetime

from pydantic import BaseModel, ConfigDict


class EquipStatusRead(BaseModel):
    """equip_status interval; PK (id, start_time); equip_id maps to equip_mst_id on ORM."""

    id: int
    equip_mst_id: int
    status_code: str | None = None
    start_time: datetime
    end_time: datetime | None = None
    model_config = ConfigDict(from_attributes=True)
