from datetime import datetime

from pydantic import BaseModel, ConfigDict


class ProdHisBase(BaseModel):
    time: datetime
    equip_id: int
    work_order_id: int | None = None
    total_cnt: int = 0
    good_cnt: int = 0
    defect_cnt: int = 0


class ProdHisCreate(ProdHisBase):
    pass


class ProdHisRead(ProdHisBase):
    id: int
    model_config = ConfigDict(from_attributes=True)
