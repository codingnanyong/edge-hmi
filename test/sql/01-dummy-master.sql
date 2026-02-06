-- ============================================================================
-- Dummy data: Master & Config (run after init-db / schema exists)
-- Schema: core. Run from test/: docker exec -i hmi-db-postgres psql -U admin -d edge_hmi -f - < sql/01-dummy-master.sql
-- ============================================================================

SET search_path TO core, public;

-- ----------------------------------------------------------------------------
-- 1. line_mst
-- ----------------------------------------------------------------------------
INSERT INTO line_mst (line_code, line_name) VALUES
  ('L001', 'Assembly Line 1'),
  ('L002', 'Assembly Line 2')
ON CONFLICT (line_code) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 2. equip_mst (line_id -> line_mst)
-- ----------------------------------------------------------------------------
INSERT INTO equip_mst (line_id, equip_code, name, type)
SELECT id, 'EQ01', 'Conveyor A', 'Conveyor' FROM line_mst WHERE line_code = 'L001' LIMIT 1
ON CONFLICT (equip_code) DO NOTHING;
INSERT INTO equip_mst (line_id, equip_code, name, type)
SELECT id, 'EQ02', 'Robot Welder 1', 'Robot' FROM line_mst WHERE line_code = 'L001' LIMIT 1
ON CONFLICT (equip_code) DO NOTHING;
INSERT INTO equip_mst (line_id, equip_code, name, type)
SELECT id, 'EQ03', 'Inspection Station', 'Vision' FROM line_mst WHERE line_code = 'L002' LIMIT 1
ON CONFLICT (equip_code) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 3. sensor_mst (equip_id -> equip_mst)
-- ----------------------------------------------------------------------------
INSERT INTO sensor_mst (equip_id, sensor_code, unit, lsl_val, usl_val, lcl_val, ucl_val)
SELECT e.id, 'TEMP01', '°C', 18.0, 28.0, 20.0, 26.0
  FROM equip_mst e WHERE e.equip_code = 'EQ01' LIMIT 1
ON CONFLICT (equip_id, sensor_code) DO NOTHING;
INSERT INTO sensor_mst (equip_id, sensor_code, unit, lsl_val, usl_val, lcl_val, ucl_val)
SELECT e.id, 'VIB01', 'mm/s', 0.0, 10.0, 1.0, 8.0
  FROM equip_mst e WHERE e.equip_code = 'EQ01' LIMIT 1
ON CONFLICT (equip_id, sensor_code) DO NOTHING;
INSERT INTO sensor_mst (equip_id, sensor_code, unit, lsl_val, usl_val, lcl_val, ucl_val)
SELECT e.id, 'CURRENT01', 'A', 0.5, 5.0, 1.0, 4.0
  FROM equip_mst e WHERE e.equip_code = 'EQ02' LIMIT 1
ON CONFLICT (equip_id, sensor_code) DO NOTHING;
INSERT INTO sensor_mst (equip_id, sensor_code, unit, lsl_val, usl_val, lcl_val, ucl_val)
SELECT e.id, 'DEFECT_RATE', '%', 0.0, 2.0, 0.0, 1.5
  FROM equip_mst e WHERE e.equip_code = 'EQ03' LIMIT 1
ON CONFLICT (equip_id, sensor_code) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 4. worker_mst
-- ----------------------------------------------------------------------------
INSERT INTO worker_mst (worker_code, name, dept_name) VALUES
  ('W001', 'Kim Hong', 'Production'),
  ('W002', 'Lee Min', 'Production'),
  ('W003', 'Park Jung', 'Maintenance')
ON CONFLICT (worker_code) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 5. shift_cfg
-- ----------------------------------------------------------------------------
INSERT INTO shift_cfg (shift_name, start_time, end_time)
SELECT 'Day', '08:00'::TIME, '16:00'::TIME WHERE NOT EXISTS (SELECT 1 FROM shift_cfg WHERE shift_name = 'Day' LIMIT 1);
INSERT INTO shift_cfg (shift_name, start_time, end_time)
SELECT 'Night', '16:00'::TIME, '24:00'::TIME WHERE NOT EXISTS (SELECT 1 FROM shift_cfg WHERE shift_name = 'Night' LIMIT 1);

-- ----------------------------------------------------------------------------
-- 6. kpi_cfg (1:1 equip, equip_id UNIQUE)
-- ----------------------------------------------------------------------------
INSERT INTO kpi_cfg (equip_id, std_cycle_time, target_oee)
SELECT id, 12.5, 85.0 FROM equip_mst WHERE equip_code = 'EQ01' LIMIT 1
ON CONFLICT (equip_id) DO NOTHING;
INSERT INTO kpi_cfg (equip_id, std_cycle_time, target_oee)
SELECT id, 8.0, 90.0 FROM equip_mst WHERE equip_code = 'EQ02' LIMIT 1
ON CONFLICT (equip_id) DO NOTHING;
INSERT INTO kpi_cfg (equip_id, std_cycle_time, target_oee)
SELECT id, 6.0, 95.0 FROM equip_mst WHERE equip_code = 'EQ03' LIMIT 1
ON CONFLICT (equip_id) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 7. alarm_cfg
-- ----------------------------------------------------------------------------
INSERT INTO alarm_cfg (alarm_code, severity, description) VALUES
  ('OVER_TEMP', 'Critical', 'Temperature exceeds upper limit'),
  ('OVER_VIB',  'Warning',  'Vibration above threshold'),
  ('CYCLE_ERR', 'Info',     'Cycle time deviation')
ON CONFLICT (alarm_code) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 8. maint_cfg
-- ----------------------------------------------------------------------------
INSERT INTO maint_cfg (maint_type, description)
SELECT 'Preventive', 'Scheduled preventive maintenance'
  WHERE NOT EXISTS (SELECT 1 FROM maint_cfg WHERE maint_type = 'Preventive' LIMIT 1);
INSERT INTO maint_cfg (maint_type, description)
SELECT 'Corrective', 'Repair after failure'
  WHERE NOT EXISTS (SELECT 1 FROM maint_cfg WHERE maint_type = 'Corrective' LIMIT 1);

-- ----------------------------------------------------------------------------
-- 9. work_order
-- ----------------------------------------------------------------------------
INSERT INTO work_order (order_no, model_name, target_cnt, sop_link, start_date, end_date) VALUES
  ('WO-2025-001', 'Model Alpha', 1000, 'https://sop.example.com/alpha', '2025-01-01 08:00:00+09', '2025-01-15 17:00:00+09'),
  ('WO-2025-002', 'Model Beta', 500, 'https://sop.example.com/beta', '2025-01-10 08:00:00+09', '2025-01-20 17:00:00+09')
ON CONFLICT (order_no) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 10. parts_mst (equip_id -> equip_mst)
-- ----------------------------------------------------------------------------
INSERT INTO parts_mst (equip_id, part_name, spec_lifespan_hours, current_usage_hours, last_replacement_date)
SELECT e.id, 'Bearing Unit A', 5000.0, 1200.0, '2024-12-01 00:00:00+09'
  FROM equip_mst e WHERE e.equip_code = 'EQ01' LIMIT 1;
INSERT INTO parts_mst (equip_id, part_name, spec_lifespan_hours, current_usage_hours, last_replacement_date)
SELECT e.id, 'Motor Brush', 2000.0, 800.0, '2024-11-15 00:00:00+09'
  FROM equip_mst e WHERE e.equip_code = 'EQ02' LIMIT 1;
INSERT INTO parts_mst (equip_id, part_name, spec_lifespan_hours, current_usage_hours, last_replacement_date)
SELECT e.id, 'Lens Assembly', 10000.0, 500.0, NULL
  FROM equip_mst e WHERE e.equip_code = 'EQ03' LIMIT 1;

-- ----------------------------------------------------------------------------
-- 11. defect_code_mst
-- ----------------------------------------------------------------------------
INSERT INTO defect_code_mst (defect_code, reason_name, category) VALUES
  ('SCRATCH', 'Surface scratch', 'Visual'),
  ('DIM_ERR', 'Dimension out of spec', 'Quality'),
  ('ASSEMBLY', 'Assembly defect', 'Process')
ON CONFLICT (defect_code) DO NOTHING;
