from pydantic import BaseModel, ConfigDict


class SensorMstBase(BaseModel):
    equip_mst_id: int
    sensor_name: str
    unit: str | None = None
    sampling_rate: float | None = None
    is_active: bool = True
    lsl_val: float | None = None
    usl_val: float | None = None
    lcl_val: float | None = None
    ucl_val: float | None = None
    is_golden_standard: bool = False
    mac_address: str | None = None


class SensorMstCreate(SensorMstBase):
    pass


class SensorMstUpdate(BaseModel):
    equip_mst_id: int | None = None
    sensor_name: str | None = None
    unit: str | None = None
    sampling_rate: float | None = None
    is_active: bool | None = None
    lsl_val: float | None = None
    usl_val: float | None = None
    lcl_val: float | None = None
    ucl_val: float | None = None
    is_golden_standard: bool | None = None
    mac_address: str | None = None


class SensorMstRead(SensorMstBase):
    id: int
    model_config = ConfigDict(from_attributes=True)
