from pydantic import BaseModel, ConfigDict


class DefectHisBase(BaseModel):
    prod_his_id: int
    defect_code_id: int
    defect_qty: int = 0


class DefectHisCreate(DefectHisBase):
    pass


class DefectHisRead(DefectHisBase):
    id: int
    model_config = ConfigDict(from_attributes=True)
