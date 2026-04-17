from datetime import datetime

from pydantic import BaseModel, ConfigDict


class AlarmHisRead(BaseModel):
    """alarm_his event log."""

    id: int
    time: datetime
    equip_mst_id: int
    alarm_cfg_id: int
    trigger_val: float | None = None
    alarm_type: str | None = None
    model_config = ConfigDict(from_attributes=True)
