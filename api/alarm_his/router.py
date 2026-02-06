from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from shared.deps import get_db
from shared.models import AlarmHis as AlarmHisModel

from alarm_his.schemas import AlarmHisRead

router = APIRouter(prefix="/alarm_his", tags=["alarm_his"])


@router.get("", response_model=list[AlarmHisRead])
def list_(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = Query(100, le=500),
    equip_id: int | None = None,
):
    q = db.query(AlarmHisModel)
    if equip_id is not None:
        q = q.filter(AlarmHisModel.equip_id == equip_id)
    return q.order_by(AlarmHisModel.id).offset(skip).limit(limit).all()


@router.get("/{id}", response_model=AlarmHisRead)
def get(id: int, db: Session = Depends(get_db)):
    row = db.get(AlarmHisModel, id)
    if not row:
        raise HTTPException(404, "alarm_his not found")
    return row

