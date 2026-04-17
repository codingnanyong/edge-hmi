from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class SensorStatusBase(BaseModel):
    """sensor_status: conn_status / update_time match init-db defaults when omitted (see router)."""

    sensor_mst_id: int
    conn_status: str = Field(default="off", description="DB NOT NULL, default off")
    last_seen: datetime | None = None
    health_score: float | None = None
    error_msg: str | None = None
    update_time: datetime | None = Field(
        default=None, description="If omitted, server uses UTC now on create"
    )


class SensorStatusCreate(SensorStatusBase):
    pass


class SensorStatusUpdate(BaseModel):
    sensor_mst_id: int | None = None
    conn_status: str | None = None
    last_seen: datetime | None = None
    health_score: float | None = None
    error_msg: str | None = None
    update_time: datetime | None = None


class SensorStatusRead(BaseModel):
    id: int
    sensor_mst_id: int
    conn_status: str
    last_seen: datetime | None = None
    health_score: float | None = None
    error_msg: str | None = None
    update_time: datetime
    model_config = ConfigDict(from_attributes=True)
