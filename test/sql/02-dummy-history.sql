-- ============================================================================
-- Dummy data: History & Analytics (run after 01-dummy-master.sql)
-- - measurement: 200 rows per sensor, in-spec + out-of-spec (~20%)
-- - equip_status_his: 매초 적재 (1시간 × 3 equip = 10,800 rows), 상태 10분마다 변경 → 트리거로 equip_status 적재
-- - alarm_his: from measurement out-of-spec
-- - prod_his, maint_his, shift_map: 100+ rows each
-- - kpi_sum: fn_kpi_sum_calc 기반 집계 (work_order_id from prod_his)
-- ============================================================================

SET search_path TO core, public;

\set base_ts '''2025-01-01 00:00:00+09'''
\set base_date '''2025-01-01'''

-- ----------------------------------------------------------------------------
-- 1. measurement: 200 rows per sensor. ~20% out-of-spec (x%5=0 fixed + random)
-- ----------------------------------------------------------------------------
INSERT INTO measurement (time, equip_id, sensor_id, value)
SELECT (:base_ts)::timestamptz + (x || ' minutes')::interval * 15, e.id, s.id,
       CASE WHEN (x % 5 = 0) OR (random() < 0.12) THEN
         CASE WHEN random() < 0.5 THEN COALESCE(s.lsl_val, 0) - (0.5 + random() * 2)
              ELSE COALESCE(s.usl_val, 1) + (0.5 + random() * 2) END
       ELSE COALESCE(s.lsl_val, 0) + random() * GREATEST(COALESCE(s.usl_val, 1) - COALESCE(s.lsl_val, 0), 0.1) END
  FROM equip_mst e
  JOIN sensor_mst s ON s.equip_id = e.id
  CROSS JOIN generate_series(0, 199) x
  WHERE (e.equip_code, s.sensor_code) = ('EQ01', 'TEMP01');

INSERT INTO measurement (time, equip_id, sensor_id, value)
SELECT (:base_ts)::timestamptz + (x || ' minutes')::interval * 15, e.id, s.id,
       CASE WHEN (x % 5 = 0) OR (random() < 0.12) THEN
         CASE WHEN random() < 0.5 THEN COALESCE(s.lsl_val, 0) - (0.5 + random() * 2)
              ELSE COALESCE(s.usl_val, 1) + (0.5 + random() * 2) END
       ELSE COALESCE(s.lsl_val, 0) + random() * GREATEST(COALESCE(s.usl_val, 1) - COALESCE(s.lsl_val, 0), 0.1) END
  FROM equip_mst e
  JOIN sensor_mst s ON s.equip_id = e.id
  CROSS JOIN generate_series(0, 199) x
  WHERE (e.equip_code, s.sensor_code) = ('EQ01', 'VIB01');

INSERT INTO measurement (time, equip_id, sensor_id, value)
SELECT (:base_ts)::timestamptz + (x || ' minutes')::interval * 15, e.id, s.id,
       CASE WHEN (x % 5 = 0) OR (random() < 0.12) THEN
         CASE WHEN random() < 0.5 THEN COALESCE(s.lsl_val, 0) - (0.5 + random() * 2)
              ELSE COALESCE(s.usl_val, 1) + (0.5 + random() * 2) END
       ELSE COALESCE(s.lsl_val, 0) + random() * GREATEST(COALESCE(s.usl_val, 1) - COALESCE(s.lsl_val, 0), 0.1) END
  FROM equip_mst e
  JOIN sensor_mst s ON s.equip_id = e.id
  CROSS JOIN generate_series(0, 199) x
  WHERE (e.equip_code, s.sensor_code) = ('EQ02', 'CURRENT01');

INSERT INTO measurement (time, equip_id, sensor_id, value)
SELECT (:base_ts)::timestamptz + (x || ' minutes')::interval * 15, e.id, s.id,
       CASE WHEN (x % 5 = 0) OR (random() < 0.12) THEN
         CASE WHEN random() < 0.5 THEN COALESCE(s.lsl_val, 0) - (0.5 + random() * 2)
              ELSE COALESCE(s.usl_val, 1) + (0.5 + random() * 2) END
       ELSE COALESCE(s.lsl_val, 0) + random() * GREATEST(COALESCE(s.usl_val, 1) - COALESCE(s.lsl_val, 0), 0.1) END
  FROM equip_mst e
  JOIN sensor_mst s ON s.equip_id = e.id
  CROSS JOIN generate_series(0, 199) x
  WHERE (e.equip_code, s.sensor_code) = ('EQ03', 'DEFECT_RATE');

-- ----------------------------------------------------------------------------
-- 2. equip_status_his: 매초 적재 (협의). 1시간 구간, 상태는 10분마다 Run→Stop→Fault 반복
--    트리거는 상태가 바뀔 때만 equip_status에 UPDATE/INSERT 함
-- ----------------------------------------------------------------------------
INSERT INTO equip_status_his (equip_id, status_code, capture_time)
SELECT sub.equip_id, sub.status_code, sub.capture_time
FROM (
  SELECT e.id AS equip_id,
         (ARRAY['Run','Stop','Fault'])[1 + ((sec::int / 600) % 3)] AS status_code,
         (:base_ts)::timestamptz + (sec || ' seconds')::interval AS capture_time
  FROM equip_mst e
  CROSS JOIN generate_series(0, 3599) sec
  ORDER BY e.id, sec
) sub;

-- ----------------------------------------------------------------------------
-- 3. prod_his: 100+ rows (3 equip × 34), work_order_id mapped
-- ----------------------------------------------------------------------------
INSERT INTO prod_his (time, equip_id, work_order_id, total_cnt, good_cnt, defect_cnt)
SELECT (:base_ts)::timestamptz + (seg || ' hours')::interval, e.id,
       (SELECT id FROM work_order WHERE order_no = 'WO-2025-001' LIMIT 1),
       100 + seg * 10, 98 + seg * 10, 2 + (seg % 5)
  FROM equip_mst e
  CROSS JOIN generate_series(0, 33) seg;

-- ----------------------------------------------------------------------------
-- 3a. defect_his: prod_his with defect_cnt > 0, 3 defect codes
-- ----------------------------------------------------------------------------
INSERT INTO defect_his (prod_his_id, defect_code_id, defect_qty)
SELECT p.id, (SELECT id FROM defect_code_mst WHERE defect_code = 'SCRATCH' LIMIT 1), q
  FROM prod_his p, LATERAL (SELECT (p.defect_cnt + 0) / 3 AS q) x WHERE x.q > 0;
INSERT INTO defect_his (prod_his_id, defect_code_id, defect_qty)
SELECT p.id, (SELECT id FROM defect_code_mst WHERE defect_code = 'DIM_ERR' LIMIT 1), q
  FROM prod_his p, LATERAL (SELECT (p.defect_cnt + 1) / 3 AS q) x WHERE x.q > 0;
INSERT INTO defect_his (prod_his_id, defect_code_id, defect_qty)
SELECT p.id, (SELECT id FROM defect_code_mst WHERE defect_code = 'ASSEMBLY' LIMIT 1),
       p.defect_cnt - ((p.defect_cnt + 0) / 3 + (p.defect_cnt + 1) / 3)
  FROM prod_his p WHERE p.defect_cnt > 0
    AND (p.defect_cnt - ((p.defect_cnt + 0) / 3 + (p.defect_cnt + 1) / 3)) > 0;

-- ----------------------------------------------------------------------------
-- 4. alarm_his: measurement out-of-spec → alarm (TEMP01→OVER_TEMP, VIB01→OVER_VIB, etc.)
-- ----------------------------------------------------------------------------
INSERT INTO alarm_his (time, equip_id, alarm_def_id, trigger_val, alarm_type)
SELECT m.time, m.equip_id,
       (SELECT id FROM alarm_cfg WHERE alarm_code =
          CASE WHEN s.sensor_code = 'TEMP01' THEN 'OVER_TEMP'
               WHEN s.sensor_code = 'VIB01' THEN 'OVER_VIB'
               ELSE 'CYCLE_ERR' END
        LIMIT 1),
       m.value,
       (ARRAY['SPEC_OUT', 'CONTROL_OUT', 'SPEC_OUT', 'SPEC_OUT', 'SYSTEM'])[1 + ((m.equip_id * 7 + m.sensor_id * 11 + EXTRACT(EPOCH FROM m.time)::bigint) % 5)]
  FROM measurement m
  JOIN sensor_mst s ON s.id = m.sensor_id AND s.equip_id = m.equip_id
  WHERE m.value < COALESCE(s.lsl_val, -1e9) OR m.value > COALESCE(s.usl_val, 1e9);

-- ----------------------------------------------------------------------------
-- 5. maint_his: 100+ rows (3 equip × 34), part_id/alarm_his_id non-NULL where possible
-- ----------------------------------------------------------------------------
INSERT INTO maint_his (equip_id, maint_def_id, part_id, worker_id, start_time, end_time, maint_desc, alarm_his_id)
SELECT e.id,
       (SELECT id FROM maint_cfg ORDER BY id LIMIT 1 OFFSET ((e.id + seg) % 2)),
       (SELECT id FROM parts_mst WHERE equip_id = e.id LIMIT 1),
       (SELECT id FROM worker_mst ORDER BY id LIMIT 1 OFFSET ((e.id + seg) % 3)),
       (:base_ts)::timestamptz + (seg * 3 + (e.id * 2) % 5) * interval '1 hour' + (seg % 4) * interval '20 minutes',
       (:base_ts)::timestamptz + (seg * 3 + (e.id * 2) % 5) * interval '1 hour' + (seg % 4) * interval '20 minutes'
         + (20 + (seg % 4) * 10) * interval '1 minute',
       (ARRAY['Preventive check', 'Corrective repair', 'Inspection', 'Parts replacement', 'Calibration'])[1 + ((e.id + seg) % 5)],
       (SELECT id FROM (SELECT id, row_number() OVER (ORDER BY time, id) AS rn FROM alarm_his WHERE equip_id = e.id) x WHERE rn = seg + 1 LIMIT 1)
  FROM equip_mst e
  CROSS JOIN generate_series(0, 33) seg
  WHERE (SELECT count(*) FROM alarm_his ah WHERE ah.equip_id = e.id) > seg;

-- ----------------------------------------------------------------------------
-- 6. shift_map: 100+ rows (50 days × 2 shifts)
-- ----------------------------------------------------------------------------
INSERT INTO shift_map (work_date, shift_def_id, worker_id, line_id, equip_id)
SELECT (:base_date)::date + d, sh.id, w.id, l.id, e.id
  FROM generate_series(0, 49) d
  CROSS JOIN (SELECT id FROM shift_cfg WHERE shift_name = 'Day' LIMIT 1) sh
  CROSS JOIN (SELECT id FROM worker_mst WHERE worker_code = 'W001' LIMIT 1) w
  CROSS JOIN (SELECT id FROM line_mst WHERE line_code = 'L001' LIMIT 1) l
  CROSS JOIN (SELECT id FROM equip_mst WHERE equip_code = 'EQ01' LIMIT 1) e;

INSERT INTO shift_map (work_date, shift_def_id, worker_id, line_id, equip_id)
SELECT (:base_date)::date + d, sh.id, w.id, l.id, e.id
  FROM generate_series(0, 49) d
  CROSS JOIN (SELECT id FROM shift_cfg WHERE shift_name = 'Night' LIMIT 1) sh
  CROSS JOIN (SELECT id FROM worker_mst WHERE worker_code = 'W002' LIMIT 1) w
  CROSS JOIN (SELECT id FROM line_mst WHERE line_code = 'L001' LIMIT 1) l
  CROSS JOIN (SELECT id FROM equip_mst WHERE equip_code = 'EQ01' LIMIT 1) e;

-- ----------------------------------------------------------------------------
-- 7. kpi_sum (fn_kpi_sum_calc)
-- ----------------------------------------------------------------------------
SELECT core.fn_kpi_sum_calc(:base_date::date);
