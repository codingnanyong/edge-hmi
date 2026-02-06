from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from shared.deps import get_db
from shared.models import MaintHis as MaintHisModel

from maint_his.schemas import MaintHisRead

router = APIRouter(prefix="/maint_his", tags=["maint_his"])


@router.get("", response_model=list[MaintHisRead])
def list_(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = Query(100, le=500),
    equip_id: int | None = None,
):
    q = db.query(MaintHisModel)
    if equip_id is not None:
        q = q.filter(MaintHisModel.equip_id == equip_id)
    return q.order_by(MaintHisModel.id).offset(skip).limit(limit).all()


@router.get("/{id}", response_model=MaintHisRead)
def get(id: int, db: Session = Depends(get_db)):
    row = db.get(MaintHisModel, id)
    if not row:
        raise HTTPException(404, "maint_his not found")
    return row

