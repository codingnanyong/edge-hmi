from pydantic import BaseModel, ConfigDict


class DefectHisCreate(BaseModel):
    prod_his_id: int
    defect_code_mst_id: int
    defect_qty: int = 0


class DefectHisRead(BaseModel):
    id: int
    prod_his_id: int
    defect_code_mst_id: int
    defect_qty: int = 0
    model_config = ConfigDict(from_attributes=True)
