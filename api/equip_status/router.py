from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from shared.deps import get_db
from shared.models import EquipStatus as EquipStatusModel

from equip_status.schemas import EquipStatusRead

router = APIRouter(prefix="/equip_status", tags=["equip_status"])


@router.get("", response_model=list[EquipStatusRead])
def list_(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = Query(100, le=500),
    equip_mst_id: int | None = None,
    start_time_from: datetime | None = None,
    start_time_to: datetime | None = None,
):
    q = db.query(EquipStatusModel)
    if equip_mst_id is not None:
        q = q.filter(EquipStatusModel.equip_mst_id == equip_mst_id)
    if start_time_from is not None:
        q = q.filter(EquipStatusModel.start_time >= start_time_from)
    if start_time_to is not None:
        q = q.filter(EquipStatusModel.start_time <= start_time_to)
    return q.order_by(EquipStatusModel.start_time).offset(skip).limit(limit).all()


@router.get("/{id}", response_model=EquipStatusRead)
def get(id: int, db: Session = Depends(get_db)):
    row = db.query(EquipStatusModel).filter(EquipStatusModel.id == id).first()
    if not row:
        raise HTTPException(404, "equip_status not found")
    return row

