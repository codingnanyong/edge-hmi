from datetime import datetime

from pydantic import BaseModel, ConfigDict


class ProdHisRead(BaseModel):
    """prod_his hypertable; PK (id, time); equip_id maps to equip_mst_id on ORM."""

    id: int
    equip_mst_id: int
    time: datetime
    work_order_id: int | None = None
    total_cnt: int = 0
    good_cnt: int = 0
    defect_cnt: int = 0
    model_config = ConfigDict(from_attributes=True)


class ProdHisCreate(BaseModel):
    equip_mst_id: int
    time: datetime
    work_order_id: int | None = None
    total_cnt: int = 0
    good_cnt: int = 0
    defect_cnt: int = 0
