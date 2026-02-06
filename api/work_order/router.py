from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from shared.deps import get_db
from shared.models import WorkOrder as WorkOrderModel

from work_order.schemas import WorkOrderCreate, WorkOrderRead, WorkOrderUpdate

router = APIRouter(prefix="/work_order", tags=["work_order"])


@router.get("", response_model=list[WorkOrderRead])
def list_(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = Query(100, le=500),
):
    return db.query(WorkOrderModel).order_by(WorkOrderModel.id).offset(skip).limit(limit).all()


@router.get("/{id}", response_model=WorkOrderRead)
def get(id: int, db: Session = Depends(get_db)):
    row = db.get(WorkOrderModel, id)
    if not row:
        raise HTTPException(404, "work_order not found")
    return row


@router.post("", response_model=WorkOrderRead, status_code=201)
def create(p: WorkOrderCreate, db: Session = Depends(get_db)):
    row = WorkOrderModel(
        order_no=p.order_no,
        model_name=p.model_name,
        target_cnt=p.target_cnt,
        sop_link=p.sop_link,
        start_date=p.start_date,
        end_date=p.end_date,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


@router.patch("/{id}", response_model=WorkOrderRead)
def update(id: int, p: WorkOrderUpdate, db: Session = Depends(get_db)):
    row = db.get(WorkOrderModel, id)
    if not row:
        raise HTTPException(404, "work_order not found")
    for k, v in p.model_dump(exclude_unset=True).items():
        setattr(row, k, v)
    db.commit()
    db.refresh(row)
    return row


@router.delete("/{id}", status_code=204)
def delete(id: int, db: Session = Depends(get_db)):
    row = db.get(WorkOrderModel, id)
    if not row:
        raise HTTPException(404, "work_order not found")
    db.delete(row)
    db.commit()
    return None
