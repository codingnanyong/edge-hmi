from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from shared.deps import get_db
from shared.models import PartsMst as PartsMstModel

from parts_mst.schemas import PartsMstCreate, PartsMstRead, PartsMstUpdate

router = APIRouter(prefix="/parts_mst", tags=["parts_mst"])


@router.get("", response_model=list[PartsMstRead])
def list_(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = Query(100, le=500),
    equip_id: int | None = None,
):
    q = db.query(PartsMstModel)
    if equip_id is not None:
        q = q.filter(PartsMstModel.equip_id == equip_id)
    return q.order_by(PartsMstModel.id).offset(skip).limit(limit).all()


@router.get("/{id}", response_model=PartsMstRead)
def get(id: int, db: Session = Depends(get_db)):
    row = db.get(PartsMstModel, id)
    if not row:
        raise HTTPException(404, "parts_mst not found")
    return row


@router.post("", response_model=PartsMstRead, status_code=201)
def create(p: PartsMstCreate, db: Session = Depends(get_db)):
    row = PartsMstModel(
        equip_id=p.equip_id,
        part_name=p.part_name,
        spec_lifespan_hours=p.spec_lifespan_hours,
        current_usage_hours=p.current_usage_hours,
        last_replacement_date=p.last_replacement_date,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


@router.patch("/{id}", response_model=PartsMstRead)
def update(id: int, p: PartsMstUpdate, db: Session = Depends(get_db)):
    row = db.get(PartsMstModel, id)
    if not row:
        raise HTTPException(404, "parts_mst not found")
    for k, v in p.model_dump(exclude_unset=True).items():
        setattr(row, k, v)
    db.commit()
    db.refresh(row)
    return row


@router.delete("/{id}", status_code=204)
def delete(id: int, db: Session = Depends(get_db)):
    row = db.get(PartsMstModel, id)
    if not row:
        raise HTTPException(404, "parts_mst not found")
    db.delete(row)
    db.commit()
    return None
