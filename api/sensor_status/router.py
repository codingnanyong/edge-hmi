from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from shared.deps import get_db
from shared.models import SensorStatus as SensorStatusModel

from sensor_status.schemas import SensorStatusCreate, SensorStatusRead, SensorStatusUpdate

router = APIRouter(prefix="/sensor_status", tags=["sensor_status"])


@router.get("", response_model=list[SensorStatusRead])
def list_(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = Query(100, le=500),
    sensor_mst_id: int | None = None,
    time_from: datetime | None = None,
    time_to: datetime | None = None,
):
    """List sensor status history (newest first). Filter by sensor_mst_id and/or update_time range."""
    q = db.query(SensorStatusModel).order_by(SensorStatusModel.update_time.desc())
    if sensor_mst_id is not None:
        q = q.filter(SensorStatusModel.sensor_mst_id == sensor_mst_id)
    if time_from is not None:
        q = q.filter(SensorStatusModel.update_time >= time_from)
    if time_to is not None:
        q = q.filter(SensorStatusModel.update_time <= time_to)
    return q.offset(skip).limit(limit).all()


@router.get("/{id}", response_model=SensorStatusRead)
def get(id: int, db: Session = Depends(get_db)):
    row = db.get(SensorStatusModel, id)
    if not row:
        raise HTTPException(404, "sensor_status not found")
    return row


@router.get("/by-sensor/{sensor_mst_id}", response_model=SensorStatusRead)
def get_by_sensor(sensor_mst_id: int, db: Session = Depends(get_db)):
    """Get latest status for a sensor (most recent update_time). Returns 404 if none."""
    row = (
        db.query(SensorStatusModel)
        .filter(SensorStatusModel.sensor_mst_id == sensor_mst_id)
        .order_by(SensorStatusModel.update_time.desc())
        .first()
    )
    if not row:
        raise HTTPException(404, "sensor_status not found for this sensor")
    return row


@router.post("", response_model=SensorStatusRead, status_code=201)
def create(p: SensorStatusCreate, db: Session = Depends(get_db)):
    """Append a new status row (cumulative history). Multiple rows per sensor allowed."""
    clamped_health = None
    if p.health_score is not None:
        clamped_health = max(0.0, min(100.0, p.health_score))
    update_time = p.update_time if p.update_time is not None else datetime.now(timezone.utc)
    conn_status = p.conn_status if p.conn_status is not None else "off"

    row = SensorStatusModel(
        sensor_mst_id=p.sensor_mst_id,
        conn_status=conn_status,
        last_seen=p.last_seen,
        health_score=clamped_health,
        error_msg=p.error_msg,
        update_time=update_time,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


@router.patch("/{id}", response_model=SensorStatusRead)
def update(id: int, p: SensorStatusUpdate, db: Session = Depends(get_db)):
    row = db.get(SensorStatusModel, id)
    if not row:
        raise HTTPException(404, "sensor_status not found")
    data = p.model_dump(exclude_unset=True)
    if "health_score" in data and data["health_score"] is not None:
        data["health_score"] = max(0.0, min(100.0, data["health_score"]))
    if "conn_status" in data and data["conn_status"] is None:
        data["conn_status"] = "off"
    for k, v in data.items():
        setattr(row, k, v)
    db.commit()
    db.refresh(row)
    return row


@router.delete("/{id}", status_code=204)
def delete(id: int, db: Session = Depends(get_db)):
    row = db.get(SensorStatusModel, id)
    if not row:
        raise HTTPException(404, "sensor_status not found")
    db.delete(row)
    db.commit()
    return None
