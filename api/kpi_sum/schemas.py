from datetime import date

from pydantic import BaseModel, ConfigDict


class KpiSumRead(BaseModel):
    id: int
    calc_date: date
    shift_cfg_id: int | None
    line_mst_id: int | None
    equip_mst_id: int | None
    work_order_id: int | None
    availability: float | None
    performance: float | None
    quality: float | None
    oee: float | None
    mttr: float | None
    mtbf: float | None
    uph: float | None
    model_config = ConfigDict(from_attributes=True)
