from datetime import datetime

from pydantic import BaseModel, ConfigDict


class WorkOrderBase(BaseModel):
    order_no: str
    model_name: str | None = None
    target_cnt: int | None = None
    sop_link: str | None = None
    start_date: datetime | None = None
    end_date: datetime | None = None


class WorkOrderCreate(WorkOrderBase):
    pass


class WorkOrderUpdate(BaseModel):
    order_no: str | None = None
    model_name: str | None = None
    target_cnt: int | None = None
    sop_link: str | None = None
    start_date: datetime | None = None
    end_date: datetime | None = None


class WorkOrderRead(WorkOrderBase):
    id: int
    model_config = ConfigDict(from_attributes=True)
