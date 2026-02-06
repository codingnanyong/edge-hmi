from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from shared.deps import get_db
from shared.models import ShiftMap as ShiftMapModel

from shift_map.schemas import ShiftMapCreate, ShiftMapRead, ShiftMapUpdate

router = APIRouter(prefix="/shift_map", tags=["shift_map"])


@router.get("", response_model=list[ShiftMapRead])
def list_(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = Query(100, le=500),
    work_date: date | None = None,
    line_id: int | None = None,
    worker_id: int | None = None,
):
    q = db.query(ShiftMapModel)
    if work_date is not None:
        q = q.filter(ShiftMapModel.work_date == work_date)
    if line_id is not None:
        q = q.filter(ShiftMapModel.line_id == line_id)
    if worker_id is not None:
        q = q.filter(ShiftMapModel.worker_id == worker_id)
    return q.order_by(ShiftMapModel.id).offset(skip).limit(limit).all()


@router.get("/{id}", response_model=ShiftMapRead)
def get(id: int, db: Session = Depends(get_db)):
    row = db.get(ShiftMapModel, id)
    if not row:
        raise HTTPException(404, "shift_map not found")
    return row


@router.post("", response_model=ShiftMapRead, status_code=201)
def create(p: ShiftMapCreate, db: Session = Depends(get_db)):
    row = ShiftMapModel(
        work_date=p.work_date,
        shift_def_id=p.shift_def_id,
        worker_id=p.worker_id,
        line_id=p.line_id,
        equip_id=p.equip_id,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


@router.patch("/{id}", response_model=ShiftMapRead)
def update(id: int, p: ShiftMapUpdate, db: Session = Depends(get_db)):
    row = db.get(ShiftMapModel, id)
    if not row:
        raise HTTPException(404, "shift_map not found")
    for k, v in p.model_dump(exclude_unset=True).items():
        setattr(row, k, v)
    db.commit()
    db.refresh(row)
    return row


@router.delete("/{id}", status_code=204)
def delete(id: int, db: Session = Depends(get_db)):
    row = db.get(ShiftMapModel, id)
    if not row:
        raise HTTPException(404, "shift_map not found")
    db.delete(row)
    db.commit()
    return None
