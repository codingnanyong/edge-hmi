from pydantic import BaseModel, ConfigDict


class DefectCodeMstBase(BaseModel):
    defect_code: str
    reason_name: str | None = None
    category: str | None = None


class DefectCodeMstCreate(DefectCodeMstBase):
    pass


class DefectCodeMstUpdate(BaseModel):
    defect_code: str | None = None
    reason_name: str | None = None
    category: str | None = None


class DefectCodeMstRead(DefectCodeMstBase):
    id: int
    model_config = ConfigDict(from_attributes=True)
