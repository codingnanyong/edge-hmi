from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from shared.deps import get_db
from shared.models import Measurement as MeasurementModel

from measurement.schemas import MeasurementRead

router = APIRouter(prefix="/measurement", tags=["measurement"])


@router.get("", response_model=list[MeasurementRead])
def list_(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = Query(100, le=1000),
    equip_mst_id: int | None = None,
    sensor_mst_id: int | None = None,
    time_from: datetime | None = None,
    time_to: datetime | None = None,
):
    q = db.query(MeasurementModel)
    if equip_mst_id is not None:
        q = q.filter(MeasurementModel.equip_mst_id == equip_mst_id)
    if sensor_mst_id is not None:
        q = q.filter(MeasurementModel.sensor_mst_id == sensor_mst_id)
    if time_from is not None:
        q = q.filter(MeasurementModel.time >= time_from)
    if time_to is not None:
        q = q.filter(MeasurementModel.time <= time_to)
    return q.order_by(MeasurementModel.time).offset(skip).limit(limit).all()

