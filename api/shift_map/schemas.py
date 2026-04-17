from datetime import date

from pydantic import BaseModel, ConfigDict


class ShiftMapBase(BaseModel):
    work_date: date
    shift_cfg_id: int
    worker_mst_id: int
    line_mst_id: int
    equip_mst_id: int | None = None


class ShiftMapCreate(ShiftMapBase):
    pass


class ShiftMapUpdate(BaseModel):
    work_date: date | None = None
    shift_cfg_id: int | None = None
    worker_mst_id: int | None = None
    line_mst_id: int | None = None
    equip_mst_id: int | None = None


class ShiftMapRead(BaseModel):
    """shift_map.id is BIGINT in DB; exposed as int."""

    id: int
    work_date: date
    shift_cfg_id: int
    worker_mst_id: int
    line_mst_id: int
    equip_mst_id: int | None = None
    model_config = ConfigDict(from_attributes=True)
