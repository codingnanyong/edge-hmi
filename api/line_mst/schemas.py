from pydantic import BaseModel, ConfigDict


class LineMstBase(BaseModel):
    plant_id: int
    factory_id: str
    process_type: str | None = None
    line_code: str
    line_name: str | None = None


class LineMstCreate(LineMstBase):
    pass


class LineMstUpdate(BaseModel):
    plant_id: int | None = None
    factory_id: str | None = None
    process_type: str | None = None
    line_code: str | None = None
    line_name: str | None = None


class LineMstRead(LineMstBase):
    id: int
    model_config = ConfigDict(from_attributes=True)
