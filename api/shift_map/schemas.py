from datetime import date

from pydantic import BaseModel, ConfigDict


class ShiftMapBase(BaseModel):
    work_date: date
    shift_def_id: int
    worker_id: int
    line_id: int
    equip_id: int | None = None


class ShiftMapCreate(ShiftMapBase):
    pass


class ShiftMapUpdate(BaseModel):
    work_date: date | None = None
    shift_def_id: int | None = None
    worker_id: int | None = None
    line_id: int | None = None
    equip_id: int | None = None


class ShiftMapRead(ShiftMapBase):
    id: int
    model_config = ConfigDict(from_attributes=True)
