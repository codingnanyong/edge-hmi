from pydantic import BaseModel, ConfigDict


class WorkerMstBase(BaseModel):
    worker_code: str
    worker_name: str
    dept_name: str | None = None
    rf_id: str | None = None


class WorkerMstCreate(WorkerMstBase):
    pass


class WorkerMstUpdate(BaseModel):
    worker_code: str | None = None
    worker_name: str | None = None
    dept_name: str | None = None
    rf_id: str | None = None


class WorkerMstRead(WorkerMstBase):
    id: int
    model_config = ConfigDict(from_attributes=True)
