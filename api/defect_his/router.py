from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from shared.deps import get_db
from shared.models import DefectHis as DefectHisModel

from defect_his.schemas import DefectHisCreate, DefectHisRead

router = APIRouter(prefix="/defect_his", tags=["defect_his"])


@router.get("", response_model=list[DefectHisRead])
def list_(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = Query(100, le=500),
    prod_his_id: int | None = None,
    defect_code_id: int | None = None,
):
    q = db.query(DefectHisModel)
    if prod_his_id is not None:
        q = q.filter(DefectHisModel.prod_his_id == prod_his_id)
    if defect_code_id is not None:
        q = q.filter(DefectHisModel.defect_code_id == defect_code_id)
    return q.order_by(DefectHisModel.id).offset(skip).limit(limit).all()


@router.get("/{id}", response_model=DefectHisRead)
def get(id: int, db: Session = Depends(get_db)):
    row = db.get(DefectHisModel, id)
    if not row:
        raise HTTPException(404, "defect_his not found")
    return row


@router.post("", response_model=DefectHisRead, status_code=201)
def create(p: DefectHisCreate, db: Session = Depends(get_db)):
    row = DefectHisModel(
        prod_his_id=p.prod_his_id,
        defect_code_id=p.defect_code_id,
        defect_qty=p.defect_qty,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row
