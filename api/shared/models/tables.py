"""ORM models for core.* tables exposed via API.

DB column names follow init-db.sql; Python attributes use *_mst_id where the API layer expects them
(via mapped_column first-arg aliases such as "equip_id", "line_id").
Pipeline-only tables (e.g. shift_sat_ext_plan) are intentionally omitted.
"""
from datetime import date, datetime, time

from sqlalchemy import (
    BigInteger,
    Boolean,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    Text,
    Time,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column

from shared.database import Base

SCHEMA = "core"


class LineMst(Base):
    __tablename__ = "line_mst"
    __table_args__ = {"schema": SCHEMA}

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    plant_id: Mapped[int] = mapped_column(Integer, nullable=False)
    factory_id: Mapped[str] = mapped_column(Text, nullable=False)
    process_type: Mapped[str | None] = mapped_column(Text)
    line_code: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    line_name: Mapped[str | None] = mapped_column(Text)


class EquipMst(Base):
    __tablename__ = "equip_mst"
    __table_args__ = {"schema": SCHEMA}

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    line_mst_id: Mapped[int] = mapped_column(
        "line_id", Integer, ForeignKey(f"{SCHEMA}.line_mst.id", ondelete="CASCADE"), nullable=False
    )
    equip_code: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    equip_name: Mapped[str] = mapped_column(Text, nullable=False)
    equip_type: Mapped[str | None] = mapped_column(Text)
    install_date: Mapped[date | None] = mapped_column(Date)


class SensorMst(Base):
    __tablename__ = "sensor_mst"
    __table_args__ = {"schema": SCHEMA}

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    equip_mst_id: Mapped[int] = mapped_column(
        "equip_id", Integer, ForeignKey(f"{SCHEMA}.equip_mst.id", ondelete="CASCADE"), nullable=False
    )
    sensor_name: Mapped[str] = mapped_column(Text, nullable=False)
    unit: Mapped[str | None] = mapped_column(Text)
    sampling_rate: Mapped[float | None] = mapped_column(Float)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    lsl_val: Mapped[float | None] = mapped_column(Float)
    usl_val: Mapped[float | None] = mapped_column(Float)
    lcl_val: Mapped[float | None] = mapped_column(Float)
    ucl_val: Mapped[float | None] = mapped_column(Float)
    is_golden_standard: Mapped[bool] = mapped_column(Boolean, default=False)
    mac_address: Mapped[str | None] = mapped_column(Text)


class WorkerMst(Base):
    __tablename__ = "worker_mst"
    __table_args__ = {"schema": SCHEMA}

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    worker_code: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    worker_name: Mapped[str] = mapped_column(Text, nullable=False)
    dept_name: Mapped[str | None] = mapped_column(Text)
    rf_id: Mapped[str | None] = mapped_column(Text)


class ShiftCfg(Base):
    __tablename__ = "shift_cfg"
    __table_args__ = {"schema": SCHEMA}

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    work_date: Mapped[date] = mapped_column(Date, nullable=False)
    shift_name: Mapped[str] = mapped_column(Text, nullable=False)
    start_time: Mapped[time] = mapped_column(Time, nullable=False)
    end_time: Mapped[time] = mapped_column(Time, nullable=False)


class KpiCfg(Base):
    __tablename__ = "kpi_cfg"
    __table_args__ = {"schema": SCHEMA}

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    equip_mst_id: Mapped[int] = mapped_column(
        "equip_id", Integer, ForeignKey(f"{SCHEMA}.equip_mst.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    std_cycle_time: Mapped[float | None] = mapped_column(Float)
    target_oee: Mapped[float | None] = mapped_column(Float)


class AlarmCfg(Base):
    __tablename__ = "alarm_cfg"
    __table_args__ = (
        UniqueConstraint("alarm_code", "sensor_id", name="uq_alarm_cfg_code_sensor"),
        {"schema": SCHEMA},
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    alarm_code: Mapped[str] = mapped_column(Text, nullable=False)
    sensor_mst_id: Mapped[int | None] = mapped_column(
        "sensor_id", Integer, ForeignKey(f"{SCHEMA}.sensor_mst.id", ondelete="SET NULL")
    )
    severity: Mapped[str | None] = mapped_column(Text)
    lower_limit: Mapped[float | None] = mapped_column(Float)
    upper_limit: Mapped[float | None] = mapped_column(Float)
    offset_val: Mapped[float | None] = mapped_column(Float)
    delay_time_sec: Mapped[int | None] = mapped_column(Integer)
    alarm_type: Mapped[str | None] = mapped_column(Text)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    description: Mapped[str | None] = mapped_column(Text)


class MaintCfg(Base):
    __tablename__ = "maint_cfg"
    __table_args__ = {"schema": SCHEMA}

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    maint_type: Mapped[str] = mapped_column(Text, nullable=False)
    description: Mapped[str | None] = mapped_column(Text)


class WorkOrder(Base):
    __tablename__ = "work_order"
    __table_args__ = {"schema": SCHEMA}

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    order_no: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    shift_map_id: Mapped[int] = mapped_column(
        Integer, ForeignKey(f"{SCHEMA}.shift_map.id", ondelete="RESTRICT"), nullable=False
    )
    model_name: Mapped[str | None] = mapped_column(Text)
    target_cnt: Mapped[int | None] = mapped_column(Integer)
    sop_link: Mapped[str | None] = mapped_column(Text)
    start_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    end_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class PartsMst(Base):
    __tablename__ = "parts_mst"
    __table_args__ = {"schema": SCHEMA}

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    equip_mst_id: Mapped[int] = mapped_column(
        "equip_id", Integer, ForeignKey(f"{SCHEMA}.equip_mst.id", ondelete="CASCADE"), nullable=False
    )
    part_name: Mapped[str] = mapped_column(Text, nullable=False)
    spec_lifespan_hours: Mapped[float | None] = mapped_column(Float)
    current_usage_hours: Mapped[float] = mapped_column(Float, default=0)
    last_replacement_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class DefectCodeMst(Base):
    __tablename__ = "defect_code_mst"
    __table_args__ = {"schema": SCHEMA}

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    defect_code: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    reason_name: Mapped[str | None] = mapped_column(Text)
    category: Mapped[str | None] = mapped_column(Text)


class Measurement(Base):
    __tablename__ = "measurement"
    __table_args__ = {"schema": SCHEMA}

    time: Mapped[datetime] = mapped_column(DateTime(timezone=True), primary_key=True, nullable=False)
    equip_mst_id: Mapped[int] = mapped_column(
        "equip_id", Integer, ForeignKey(f"{SCHEMA}.equip_mst.id", ondelete="RESTRICT"), primary_key=True, nullable=False
    )
    sensor_mst_id: Mapped[int] = mapped_column(
        "sensor_id", Integer, ForeignKey(f"{SCHEMA}.sensor_mst.id", ondelete="RESTRICT"), primary_key=True, nullable=False
    )
    value: Mapped[float | None] = mapped_column(Float)


class EquipStatus(Base):
    """equip_status hypertable; PK (id, start_time) per init-db.sql."""

    __tablename__ = "equip_status"
    __table_args__ = {"schema": SCHEMA}

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    equip_mst_id: Mapped[int] = mapped_column(
        "equip_id", Integer, ForeignKey(f"{SCHEMA}.equip_mst.id", ondelete="RESTRICT"), nullable=False
    )
    status_code: Mapped[str | None] = mapped_column(Text)
    start_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), primary_key=True, nullable=False)
    end_time: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class SensorStatus(Base):
    __tablename__ = "sensor_status"
    __table_args__ = {"schema": SCHEMA}

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    sensor_mst_id: Mapped[int] = mapped_column(
        "sensor_id", Integer, ForeignKey(f"{SCHEMA}.sensor_mst.id", ondelete="CASCADE"), nullable=False
    )
    conn_status: Mapped[str] = mapped_column(Text, nullable=False, default="off")
    last_seen: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    health_score: Mapped[float | None] = mapped_column(Float)
    error_msg: Mapped[str | None] = mapped_column(Text)
    update_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class EquipStatusHis(Base):
    """equip_status_his hypertable; PK (id, capture_time) per init-db.sql."""

    __tablename__ = "equip_status_his"
    __table_args__ = {"schema": SCHEMA}

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    equip_mst_id: Mapped[int] = mapped_column(
        "equip_id", Integer, ForeignKey(f"{SCHEMA}.equip_mst.id", ondelete="RESTRICT"), nullable=False
    )
    status_code: Mapped[str | None] = mapped_column(Text)
    capture_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), primary_key=True, nullable=False)


class ProdHis(Base):
    """prod_his hypertable; PK (id, time) per init-db.sql."""

    __tablename__ = "prod_his"
    __table_args__ = {"schema": SCHEMA}

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    time: Mapped[datetime] = mapped_column(DateTime(timezone=True), primary_key=True, nullable=False)
    equip_mst_id: Mapped[int] = mapped_column(
        "equip_id", Integer, ForeignKey(f"{SCHEMA}.equip_mst.id", ondelete="RESTRICT"), nullable=False
    )
    work_order_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey(f"{SCHEMA}.work_order.id", ondelete="SET NULL")
    )
    total_cnt: Mapped[int] = mapped_column(Integer, default=0)
    good_cnt: Mapped[int] = mapped_column(Integer, default=0)
    defect_cnt: Mapped[int] = mapped_column(Integer, default=0)


class DefectHis(Base):
    __tablename__ = "defect_his"
    __table_args__ = {"schema": SCHEMA}

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    prod_his_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    defect_code_mst_id: Mapped[int] = mapped_column(
        "defect_code_id", Integer, ForeignKey(f"{SCHEMA}.defect_code_mst.id", ondelete="RESTRICT"), nullable=False
    )
    defect_qty: Mapped[int] = mapped_column(Integer, default=0)


class AlarmHis(Base):
    __tablename__ = "alarm_his"
    __table_args__ = {"schema": SCHEMA}

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    equip_mst_id: Mapped[int] = mapped_column(
        "equip_id", Integer, ForeignKey(f"{SCHEMA}.equip_mst.id", ondelete="RESTRICT"), nullable=False
    )
    alarm_cfg_id: Mapped[int] = mapped_column(
        Integer, ForeignKey(f"{SCHEMA}.alarm_cfg.id", ondelete="RESTRICT"), nullable=False
    )
    trigger_val: Mapped[float | None] = mapped_column(Float)
    alarm_type: Mapped[str | None] = mapped_column(Text)


class MaintHis(Base):
    __tablename__ = "maint_his"
    __table_args__ = {"schema": SCHEMA}

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    equip_mst_id: Mapped[int] = mapped_column(
        "equip_id", Integer, ForeignKey(f"{SCHEMA}.equip_mst.id", ondelete="RESTRICT"), nullable=False
    )
    maint_cfg_id: Mapped[int] = mapped_column(
        Integer, ForeignKey(f"{SCHEMA}.maint_cfg.id", ondelete="RESTRICT"), nullable=False
    )
    parts_mst_id: Mapped[int | None] = mapped_column(
        "part_id", Integer, ForeignKey(f"{SCHEMA}.parts_mst.id", ondelete="SET NULL")
    )
    alarm_his_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey(f"{SCHEMA}.alarm_his.id", ondelete="SET NULL"), unique=True
    )
    worker_mst_id: Mapped[int | None] = mapped_column(
        "worker_id", Integer, ForeignKey(f"{SCHEMA}.worker_mst.id", ondelete="SET NULL")
    )
    start_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    end_time: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    maint_desc: Mapped[str | None] = mapped_column(Text)


class ShiftMap(Base):
    __tablename__ = "shift_map"
    __table_args__ = {"schema": SCHEMA}

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    work_date: Mapped[date] = mapped_column(Date, nullable=False)
    shift_cfg_id: Mapped[int] = mapped_column(
        Integer, ForeignKey(f"{SCHEMA}.shift_cfg.id", ondelete="RESTRICT"), nullable=False
    )
    worker_mst_id: Mapped[int] = mapped_column(
        "worker_id", Integer, ForeignKey(f"{SCHEMA}.worker_mst.id", ondelete="RESTRICT"), nullable=False
    )
    line_mst_id: Mapped[int] = mapped_column(
        "line_id", Integer, ForeignKey(f"{SCHEMA}.line_mst.id", ondelete="RESTRICT"), nullable=False
    )
    equip_mst_id: Mapped[int | None] = mapped_column(
        "equip_id", Integer, ForeignKey(f"{SCHEMA}.equip_mst.id", ondelete="SET NULL")
    )


class KpiSum(Base):
    __tablename__ = "kpi_sum"
    __table_args__ = {"schema": SCHEMA}

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    calc_date: Mapped[date] = mapped_column(Date, nullable=False)
    shift_cfg_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey(f"{SCHEMA}.shift_cfg.id", ondelete="SET NULL")
    )
    line_mst_id: Mapped[int | None] = mapped_column(
        "line_id", Integer, ForeignKey(f"{SCHEMA}.line_mst.id", ondelete="SET NULL")
    )
    equip_mst_id: Mapped[int | None] = mapped_column(
        "equip_id", Integer, ForeignKey(f"{SCHEMA}.equip_mst.id", ondelete="SET NULL")
    )
    work_order_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey(f"{SCHEMA}.work_order.id", ondelete="SET NULL")
    )
    availability: Mapped[float | None] = mapped_column(Float)
    performance: Mapped[float | None] = mapped_column(Float)
    quality: Mapped[float | None] = mapped_column(Float)
    oee: Mapped[float | None] = mapped_column(Float)
    mttr: Mapped[float | None] = mapped_column(Float)
    mtbf: Mapped[float | None] = mapped_column(Float)
    uph: Mapped[float | None] = mapped_column(Float)
