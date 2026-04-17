from datetime import datetime

from pydantic import BaseModel, ConfigDict


class MaintHisRead(BaseModel):
    """maint_his activity log."""

    id: int
    equip_mst_id: int
    maint_cfg_id: int
    parts_mst_id: int | None = None
    alarm_his_id: int | None = None
    worker_mst_id: int | None = None
    start_time: datetime
    end_time: datetime | None = None
    maint_desc: str | None = None
    model_config = ConfigDict(from_attributes=True)
