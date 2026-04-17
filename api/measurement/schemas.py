from datetime import datetime

from pydantic import BaseModel, ConfigDict


class MeasurementRead(BaseModel):
    """measurement hypertable; PK (time, equip_mst_id, sensor_mst_id)."""

    time: datetime
    equip_mst_id: int
    sensor_mst_id: int
    value: float | None = None
    model_config = ConfigDict(from_attributes=True)
