from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from shared.deps import get_db
from shared.models import DefectCodeMst as DefectCodeMstModel

from defect_code_mst.schemas import DefectCodeMstCreate, DefectCodeMstRead, DefectCodeMstUpdate

router = APIRouter(prefix="/defect_code_mst", tags=["defect_code_mst"])


@router.get("", response_model=list[DefectCodeMstRead])
def list_(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = Query(100, le=500),
    category: str | None = None,
):
    q = db.query(DefectCodeMstModel)
    if category is not None:
        q = q.filter(DefectCodeMstModel.category == category)
    return q.order_by(DefectCodeMstModel.id).offset(skip).limit(limit).all()


@router.get("/{id}", response_model=DefectCodeMstRead)
def get(id: int, db: Session = Depends(get_db)):
    row = db.get(DefectCodeMstModel, id)
    if not row:
        raise HTTPException(404, "defect_code_mst not found")
    return row


@router.post("", response_model=DefectCodeMstRead, status_code=201)
def create(p: DefectCodeMstCreate, db: Session = Depends(get_db)):
    row = DefectCodeMstModel(
        defect_code=p.defect_code,
        reason_name=p.reason_name,
        category=p.category,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


@router.patch("/{id}", response_model=DefectCodeMstRead)
def update(id: int, p: DefectCodeMstUpdate, db: Session = Depends(get_db)):
    row = db.get(DefectCodeMstModel, id)
    if not row:
        raise HTTPException(404, "defect_code_mst not found")
    for k, v in p.model_dump(exclude_unset=True).items():
        setattr(row, k, v)
    db.commit()
    db.refresh(row)
    return row


@router.delete("/{id}", status_code=204)
def delete(id: int, db: Session = Depends(get_db)):
    row = db.get(DefectCodeMstModel, id)
    if not row:
        raise HTTPException(404, "defect_code_mst not found")
    db.delete(row)
    db.commit()
    return None
