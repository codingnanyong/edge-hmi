from datetime import date

from pydantic import BaseModel, ConfigDict


class EquipMstBase(BaseModel):
    line_mst_id: int
    equip_code: str
    equip_name: str
    equip_type: str | None = None
    install_date: date | None = None


class EquipMstCreate(EquipMstBase):
    pass


class EquipMstUpdate(BaseModel):
    line_mst_id: int | None = None
    equip_code: str | None = None
    equip_name: str | None = None
    equip_type: str | None = None
    install_date: date | None = None


class EquipMstRead(EquipMstBase):
    id: int
    model_config = ConfigDict(from_attributes=True)
