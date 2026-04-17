from pydantic import BaseModel, ConfigDict


class AlarmCfgBase(BaseModel):
    alarm_code: str
    sensor_mst_id: int | None = None
    severity: str | None = None
    lower_limit: float | None = None
    upper_limit: float | None = None
    offset_val: float | None = None
    delay_time_sec: int | None = None
    alarm_type: str | None = None
    is_active: bool = True
    description: str | None = None


class AlarmCfgCreate(AlarmCfgBase):
    pass


class AlarmCfgUpdate(BaseModel):
    alarm_code: str | None = None
    sensor_mst_id: int | None = None
    severity: str | None = None
    lower_limit: float | None = None
    upper_limit: float | None = None
    offset_val: float | None = None
    delay_time_sec: int | None = None
    alarm_type: str | None = None
    is_active: bool | None = None
    description: str | None = None


class AlarmCfgRead(AlarmCfgBase):
    id: int
    model_config = ConfigDict(from_attributes=True)
