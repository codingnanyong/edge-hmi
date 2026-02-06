from pydantic import BaseModel, ConfigDict


class SensorMstBase(BaseModel):
    equip_id: int
    sensor_code: str
    unit: str | None = None
    lsl_val: float | None = None
    usl_val: float | None = None
    lcl_val: float | None = None
    ucl_val: float | None = None
    is_golden_standard: bool = False


class SensorMstCreate(SensorMstBase):
    pass


class SensorMstUpdate(BaseModel):
    equip_id: int | None = None
    sensor_code: str | None = None
    unit: str | None = None
    lsl_val: float | None = None
    usl_val: float | None = None
    lcl_val: float | None = None
    ucl_val: float | None = None
    is_golden_standard: bool | None = None


class SensorMstRead(SensorMstBase):
    id: int
    model_config = ConfigDict(from_attributes=True)
