-- ============================================================================
-- Edge HMI Database Schema (Full Relational Version)
-- DBML spec v2: FK relationships, extensibility
-- ============================================================================
-- Timezone: fixed here (override via container TZ for runtime; storage remains UTC).
-- Change 'Asia/Seoul' if required for your deployment.
-- ============================================================================

SET timezone = 'Asia/Seoul';
DO $$
DECLARE
  db text := current_database();
  tz text := 'Asia/Seoul';
BEGIN
  EXECUTE format('ALTER DATABASE %I SET timezone = %L', db, tz);
  RAISE NOTICE 'Database [%] timezone set to: %', db, tz;
  RAISE NOTICE 'Current time: %', now();
END
$$;

CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ----------------------------------------------------------------------------
-- [0. Schema Setup]
-- ----------------------------------------------------------------------------
-- Standard schema name: core. Keep .env POSTGRES_SCHEMA=core.
CREATE SCHEMA IF NOT EXISTS core;
COMMENT ON SCHEMA core IS 'Edge HMI application tables: master, history, analytics';

SET search_path TO core, public;
DO $$
BEGIN
  EXECUTE format('ALTER DATABASE %I SET search_path TO core, public', current_database());
END $$;

GRANT USAGE ON SCHEMA core TO CURRENT_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT ALL ON TABLES TO CURRENT_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT ALL ON SEQUENCES TO CURRENT_USER;

-- ----------------------------------------------------------------------------
-- [1. Master & Definition]
-- ----------------------------------------------------------------------------

-- 1.1 Line master
CREATE TABLE IF NOT EXISTS line_mst (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    process_type VARCHAR(50),
    line_code VARCHAR(50) UNIQUE NOT NULL,
    line_name VARCHAR(200)
);
COMMENT ON TABLE line_mst IS 'Production line master';
COMMENT ON COLUMN line_mst.process_type IS 'Process type (e.g. assembly, test)';
COMMENT ON COLUMN line_mst.line_code IS 'Line identifier code';
COMMENT ON COLUMN line_mst.line_name IS 'Line display name';

-- 1.2 Equipment master (Line -> Equip)
CREATE TABLE IF NOT EXISTS equip_mst (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    line_id INTEGER NOT NULL REFERENCES line_mst(id) ON DELETE CASCADE,
    equip_code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    type VARCHAR(100),
    install_date DATE
);
COMMENT ON TABLE equip_mst IS 'Equipment master; belongs to a line';
COMMENT ON COLUMN equip_mst.line_id IS 'Owning line (single/same/mixed line)';
COMMENT ON COLUMN equip_mst.equip_code IS 'Equipment unique ID';
COMMENT ON COLUMN equip_mst.name IS 'Equipment name';
COMMENT ON COLUMN equip_mst.type IS 'Equipment type';
COMMENT ON COLUMN equip_mst.install_date IS 'Equipment installation date';

-- 1.3 Sensor master (Equip -> Sensor)
CREATE TABLE IF NOT EXISTS sensor_mst (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    equip_id INTEGER NOT NULL REFERENCES equip_mst(id) ON DELETE CASCADE,
    sensor_code VARCHAR(50) NOT NULL,
    unit VARCHAR(20),
    lsl_val FLOAT,
    usl_val FLOAT,
    lcl_val FLOAT,
    ucl_val FLOAT,
    is_golden_standard BOOLEAN DEFAULT FALSE,
    CONSTRAINT uq_sensor_equip_code UNIQUE (equip_id, sensor_code)
);
COMMENT ON TABLE sensor_mst IS 'Sensor master; attached to equipment';
COMMENT ON COLUMN sensor_mst.equip_id IS 'Parent equipment';
COMMENT ON COLUMN sensor_mst.sensor_code IS 'Sensor code within equipment';
COMMENT ON COLUMN sensor_mst.unit IS 'Measurement unit';
COMMENT ON COLUMN sensor_mst.lsl_val IS 'Lower Spec Limit';
COMMENT ON COLUMN sensor_mst.usl_val IS 'Upper Spec Limit';
COMMENT ON COLUMN sensor_mst.lcl_val IS 'Lower Control Limit';
COMMENT ON COLUMN sensor_mst.ucl_val IS 'Upper Control Limit';
COMMENT ON COLUMN sensor_mst.is_golden_standard IS 'Golden standard sensor for comparison';

-- 1.4 Worker & shift config
CREATE TABLE IF NOT EXISTS worker_mst (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    worker_code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    dept_name VARCHAR(100)
);
COMMENT ON TABLE worker_mst IS 'Worker/operator master';
COMMENT ON COLUMN worker_mst.worker_code IS 'Worker ID';
COMMENT ON COLUMN worker_mst.name IS 'Worker full name';
COMMENT ON COLUMN worker_mst.dept_name IS 'Department name';

CREATE TABLE IF NOT EXISTS shift_cfg (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    shift_name VARCHAR(50) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL
);
COMMENT ON TABLE shift_cfg IS 'Shift schedule definition';
COMMENT ON COLUMN shift_cfg.shift_name IS 'Day, night, etc.';
COMMENT ON COLUMN shift_cfg.start_time IS 'Shift start time';
COMMENT ON COLUMN shift_cfg.end_time IS 'Shift end time';

-- 1.5 Config (1:1 or N:1)
CREATE TABLE IF NOT EXISTS kpi_cfg (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    equip_id INTEGER UNIQUE NOT NULL REFERENCES equip_mst(id) ON DELETE CASCADE,
    std_cycle_time FLOAT,
    target_oee FLOAT
);
COMMENT ON TABLE kpi_cfg IS 'KPI config per equipment (1:1)';
COMMENT ON COLUMN kpi_cfg.equip_id IS 'Target equipment';
COMMENT ON COLUMN kpi_cfg.std_cycle_time IS 'Standard cycle time for performance';
COMMENT ON COLUMN kpi_cfg.target_oee IS 'Target OEE';

CREATE TABLE IF NOT EXISTS alarm_cfg (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    alarm_code VARCHAR(50) UNIQUE NOT NULL,
    severity VARCHAR(20),
    description TEXT
);
COMMENT ON TABLE alarm_cfg IS 'Alarm type definition';
COMMENT ON COLUMN alarm_cfg.alarm_code IS 'Alarm type code';
COMMENT ON COLUMN alarm_cfg.severity IS 'Critical, Warning, Info';
COMMENT ON COLUMN alarm_cfg.description IS 'Alarm description';

CREATE TABLE IF NOT EXISTS maint_cfg (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    maint_type VARCHAR(50) NOT NULL,
    description TEXT
);
COMMENT ON TABLE maint_cfg IS 'Maintenance type definition';
COMMENT ON COLUMN maint_cfg.maint_type IS 'Preventive, corrective, etc.';
COMMENT ON COLUMN maint_cfg.description IS 'Maintenance description';

-- 1.6 Work order (production order)
CREATE TABLE IF NOT EXISTS work_order (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    order_no VARCHAR(50) UNIQUE NOT NULL,
    model_name VARCHAR(200),
    target_cnt INTEGER,
    sop_link VARCHAR(500),
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ
);
COMMENT ON TABLE work_order IS 'Production work order';
COMMENT ON COLUMN work_order.order_no IS 'Work order number';
COMMENT ON COLUMN work_order.model_name IS 'Product model name';
COMMENT ON COLUMN work_order.target_cnt IS 'Target production count';
COMMENT ON COLUMN work_order.sop_link IS 'SOP document link';
COMMENT ON COLUMN work_order.start_date IS 'Order start date';
COMMENT ON COLUMN work_order.end_date IS 'Order end date';

-- 1.7 Parts master (Equip -> Parts)
CREATE TABLE IF NOT EXISTS parts_mst (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    equip_id INTEGER NOT NULL REFERENCES equip_mst(id) ON DELETE CASCADE,
    part_name VARCHAR(200) NOT NULL,
    spec_lifespan_hours FLOAT,
    current_usage_hours FLOAT DEFAULT 0,
    last_replacement_date TIMESTAMPTZ
);
COMMENT ON TABLE parts_mst IS 'Parts/spare master per equipment';
COMMENT ON COLUMN parts_mst.equip_id IS 'Parent equipment';
COMMENT ON COLUMN parts_mst.part_name IS 'Part name';
COMMENT ON COLUMN parts_mst.spec_lifespan_hours IS 'Specified lifespan in hours';
COMMENT ON COLUMN parts_mst.current_usage_hours IS 'Current usage hours';
COMMENT ON COLUMN parts_mst.last_replacement_date IS 'Last replacement timestamp';

-- 1.8 Defect code master
CREATE TABLE IF NOT EXISTS defect_code_mst (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    defect_code VARCHAR(50) UNIQUE NOT NULL,
    reason_name VARCHAR(200),
    category VARCHAR(100)
);
COMMENT ON TABLE defect_code_mst IS 'Defect reason code definition';
COMMENT ON COLUMN defect_code_mst.defect_code IS 'Defect code';
COMMENT ON COLUMN defect_code_mst.reason_name IS 'Reason display name';
COMMENT ON COLUMN defect_code_mst.category IS 'Defect category';


-- ----------------------------------------------------------------------------
-- [2. History & Assignment]
-- ----------------------------------------------------------------------------

-- 2.1 Measurement (TimescaleDB hypertable: sensor raw data)
CREATE TABLE IF NOT EXISTS measurement (
    time TIMESTAMPTZ NOT NULL,
    equip_id INTEGER NOT NULL REFERENCES equip_mst(id) ON DELETE RESTRICT,
    sensor_id INTEGER NOT NULL REFERENCES sensor_mst(id) ON DELETE RESTRICT,
    value FLOAT,
    PRIMARY KEY (time, equip_id, sensor_id)
);
SELECT create_hypertable('measurement', 'time', chunk_time_interval => INTERVAL '1 day', if_not_exists => TRUE);
COMMENT ON TABLE measurement IS 'TimescaleDB hypertable: sensor raw data';
COMMENT ON COLUMN measurement.time IS 'Measurement timestamp (partition key)';
COMMENT ON COLUMN measurement.equip_id IS 'Equipment';
COMMENT ON COLUMN measurement.sensor_id IS 'Sensor';
COMMENT ON COLUMN measurement.value IS 'Measured value';

-- 2.2 Status history (availability: Run/Stop/Fault)
CREATE TABLE IF NOT EXISTS status_his (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    equip_id INTEGER NOT NULL REFERENCES equip_mst(id) ON DELETE RESTRICT,
    status_code text,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    PRIMARY KEY (id, start_time)
);
SELECT create_hypertable('status_his', 'start_time', chunk_time_interval => INTERVAL '1 day', if_not_exists => TRUE);
COMMENT ON TABLE status_his IS 'Availability (Run/Stop/Fault)';
COMMENT ON COLUMN status_his.equip_id IS 'Equipment';
COMMENT ON COLUMN status_his.status_code IS 'Run, Stop, Fault, etc.';
COMMENT ON COLUMN status_his.start_time IS 'Status start (partition key)';
COMMENT ON COLUMN status_his.end_time IS 'Status end; NULL if ongoing';

-- 2.3 Production history (performance/quality)
CREATE TABLE IF NOT EXISTS prod_his (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    time TIMESTAMPTZ NOT NULL,
    equip_id INTEGER NOT NULL REFERENCES equip_mst(id) ON DELETE RESTRICT,
    work_order_id INTEGER REFERENCES work_order(id) ON DELETE SET NULL,
    total_cnt INTEGER DEFAULT 0,
    good_cnt INTEGER DEFAULT 0,
    defect_cnt INTEGER DEFAULT 0,
    PRIMARY KEY (id, time)
);
SELECT create_hypertable('prod_his', 'time', chunk_time_interval => INTERVAL '1 day', if_not_exists => TRUE);
COMMENT ON TABLE prod_his IS 'Performance/quality metrics';
COMMENT ON COLUMN prod_his.time IS 'Record timestamp (partition key)';
COMMENT ON COLUMN prod_his.equip_id IS 'Equipment';
COMMENT ON COLUMN prod_his.work_order_id IS 'Related work order';
COMMENT ON COLUMN prod_his.total_cnt IS 'Total count';
COMMENT ON COLUMN prod_his.good_cnt IS 'Good count';
COMMENT ON COLUMN prod_his.defect_cnt IS 'Defect count';

-- 2.3a Defect history (Prod_His, Defect_Code_Mst)
-- Note: No FK to prod_his (hypertable PK is id+time; TimescaleDB disallows FK on id-only).
-- Application ensures prod_his_id refers to valid prod_his(id).
CREATE TABLE IF NOT EXISTS defect_his (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    prod_his_id BIGINT NOT NULL,
    defect_code_id INTEGER NOT NULL REFERENCES defect_code_mst(id) ON DELETE RESTRICT,
    defect_qty INTEGER DEFAULT 0
);
COMMENT ON TABLE defect_his IS 'Defect detail by reason code per production record';
COMMENT ON COLUMN defect_his.prod_his_id IS 'Production history record';
COMMENT ON COLUMN defect_his.defect_code_id IS 'Defect reason (defect_code_mst)';
COMMENT ON COLUMN defect_his.defect_qty IS 'Defect quantity for this code';

-- 2.4 Alarm history (Equip, Alarm_Cfg)
CREATE TABLE IF NOT EXISTS alarm_his (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    time TIMESTAMPTZ NOT NULL,
    equip_id INTEGER NOT NULL REFERENCES equip_mst(id) ON DELETE RESTRICT,
    alarm_def_id INTEGER NOT NULL REFERENCES alarm_cfg(id) ON DELETE RESTRICT,
    trigger_val FLOAT,
    alarm_type VARCHAR(50)
);
COMMENT ON TABLE alarm_his IS 'Alarm event log';
COMMENT ON COLUMN alarm_his.time IS 'Alarm timestamp';
COMMENT ON COLUMN alarm_his.equip_id IS 'Equipment';
COMMENT ON COLUMN alarm_his.alarm_def_id IS 'Alarm type (alarm_cfg)';
COMMENT ON COLUMN alarm_his.trigger_val IS 'Measurement at alarm trigger';
COMMENT ON COLUMN alarm_his.alarm_type IS 'SPEC_OUT, CONTROL_OUT, SYSTEM';

-- 2.5 Maintenance history (Equip, Maint_Cfg, Parts_Mst, Alarm_His, Worker)
CREATE TABLE IF NOT EXISTS maint_his (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    equip_id INTEGER NOT NULL REFERENCES equip_mst(id) ON DELETE RESTRICT,
    maint_def_id INTEGER NOT NULL REFERENCES maint_cfg(id) ON DELETE RESTRICT,
    part_id INTEGER REFERENCES parts_mst(id) ON DELETE SET NULL,
    alarm_his_id INTEGER UNIQUE REFERENCES alarm_his(id) ON DELETE SET NULL,
    worker_id INTEGER REFERENCES worker_mst(id) ON DELETE SET NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    maint_desc TEXT
);
COMMENT ON TABLE maint_his IS 'Maintenance activity log';
COMMENT ON COLUMN maint_his.equip_id IS 'Equipment';
COMMENT ON COLUMN maint_his.maint_def_id IS 'Maintenance type (maint_cfg)';
COMMENT ON COLUMN maint_his.part_id IS 'Replaced part (parts_mst)';
COMMENT ON COLUMN maint_his.alarm_his_id IS 'Related alarm history';
COMMENT ON COLUMN maint_his.worker_id IS 'Maintenance performer';
COMMENT ON COLUMN maint_his.start_time IS 'Maintenance start';
COMMENT ON COLUMN maint_his.end_time IS 'Maintenance end';
COMMENT ON COLUMN maint_his.maint_desc IS 'Maintenance notes';

-- 2.6 Shift assignment (Date, Shift, Worker, Line, Equip)
CREATE TABLE IF NOT EXISTS shift_map (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    work_date DATE NOT NULL,
    shift_def_id INTEGER NOT NULL REFERENCES shift_cfg(id) ON DELETE RESTRICT,
    worker_id INTEGER NOT NULL REFERENCES worker_mst(id) ON DELETE RESTRICT,
    line_id INTEGER NOT NULL REFERENCES line_mst(id) ON DELETE RESTRICT,
    equip_id INTEGER REFERENCES equip_mst(id) ON DELETE SET NULL
);
COMMENT ON TABLE shift_map IS 'Worker–shift–line–equip assignment per date';
COMMENT ON COLUMN shift_map.work_date IS 'Assignment date';
COMMENT ON COLUMN shift_map.shift_def_id IS 'Shift (shift_cfg)';
COMMENT ON COLUMN shift_map.worker_id IS 'Worker';
COMMENT ON COLUMN shift_map.line_id IS 'Line';
COMMENT ON COLUMN shift_map.equip_id IS 'When assigned to specific equipment';


-- ----------------------------------------------------------------------------
-- [3. Analytics Summary]
-- ----------------------------------------------------------------------------

-- 3.1 KPI aggregate (Shift, Line, Equip, Work_Order)
CREATE TABLE IF NOT EXISTS kpi_sum (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    calc_date DATE NOT NULL,
    shift_def_id INTEGER REFERENCES shift_cfg(id) ON DELETE SET NULL,
    line_id INTEGER REFERENCES line_mst(id) ON DELETE SET NULL,
    equip_id INTEGER REFERENCES equip_mst(id) ON DELETE SET NULL,
    work_order_id INTEGER REFERENCES work_order(id) ON DELETE SET NULL,
    availability FLOAT,
    performance FLOAT,
    quality FLOAT,
    oee FLOAT,
    mttr FLOAT,
    mtbf FLOAT,
    uph FLOAT
);
COMMENT ON TABLE kpi_sum IS 'KPI aggregates by date/shift/line/equip/work order';
COMMENT ON COLUMN kpi_sum.calc_date IS 'Aggregation date';
COMMENT ON COLUMN kpi_sum.shift_def_id IS 'Shift (nullable)';
COMMENT ON COLUMN kpi_sum.line_id IS 'Line (nullable)';
COMMENT ON COLUMN kpi_sum.equip_id IS 'Equipment (nullable)';
COMMENT ON COLUMN kpi_sum.work_order_id IS 'Work order (nullable)';
COMMENT ON COLUMN kpi_sum.availability IS 'Availability';
COMMENT ON COLUMN kpi_sum.performance IS 'Performance';
COMMENT ON COLUMN kpi_sum.quality IS 'Quality';
COMMENT ON COLUMN kpi_sum.oee IS 'OEE';
COMMENT ON COLUMN kpi_sum.mttr IS 'Mean time to repair';
COMMENT ON COLUMN kpi_sum.mtbf IS 'Mean time between failures';
COMMENT ON COLUMN kpi_sum.uph IS 'Units per hour';

-- ----------------------------------------------------------------------------
-- [4. Indexes]
-- ----------------------------------------------------------------------------

-- measurement: equip- and sensor-based time-range queries
CREATE INDEX IF NOT EXISTS idx_measurement_equip_time ON measurement (equip_id, time DESC);
CREATE INDEX IF NOT EXISTS idx_measurement_sensor_time ON measurement (sensor_id, time DESC);
-- status_his: equipment status over time
CREATE INDEX IF NOT EXISTS idx_status_his_equip_start ON status_his (equip_id, start_time DESC);
-- prod_his: production by equipment and time, work order
CREATE INDEX IF NOT EXISTS idx_prod_his_equip_time ON prod_his (equip_id, time DESC);
CREATE INDEX IF NOT EXISTS idx_prod_his_work_order ON prod_his (work_order_id);
-- defect_his: by production record and defect code
CREATE INDEX IF NOT EXISTS idx_defect_his_prod ON defect_his (prod_his_id);
CREATE INDEX IF NOT EXISTS idx_defect_his_code ON defect_his (defect_code_id);
-- alarm_his: alarms by equipment, time
CREATE INDEX IF NOT EXISTS idx_alarm_his_equip_time ON alarm_his (equip_id, time DESC);
CREATE INDEX IF NOT EXISTS idx_alarm_his_time ON alarm_his (time DESC);
-- maint_his: maintenance by equipment and start time
CREATE INDEX IF NOT EXISTS idx_maint_his_equip_start ON maint_his (equip_id, start_time DESC);
-- shift_map: lookups by date, worker
CREATE INDEX IF NOT EXISTS idx_shift_map_work_date ON shift_map (work_date);
CREATE INDEX IF NOT EXISTS idx_shift_map_worker ON shift_map (worker_id);
-- kpi_sum: aggregates by date, equipment, work order
CREATE INDEX IF NOT EXISTS idx_kpi_sum_calc_date ON kpi_sum (calc_date);
CREATE INDEX IF NOT EXISTS idx_kpi_sum_equip ON kpi_sum (equip_id);
CREATE INDEX IF NOT EXISTS idx_kpi_sum_work_order ON kpi_sum (work_order_id);

-- ----------------------------------------------------------------------------
-- [5. TimescaleDB Policies]
-- ----------------------------------------------------------------------------
-- measurement: compress by equip_id,sensor_id; compress chunks older than 3 days;
-- drop chunks older than 1 month.

ALTER TABLE measurement SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'equip_id,sensor_id'
);
SELECT add_compression_policy('measurement', INTERVAL '3 days', if_not_exists => TRUE);
SELECT add_retention_policy('measurement', INTERVAL '1 month', if_not_exists => TRUE);
