-- ============================================================================
-- KPI Summary Scheduler
-- ============================================================================
-- Run after init-db.sql. Populates kpi_sum from status_his, prod_his, alarm_his,
-- maint_his, shift_map, kpi_cfg per (calc_date, shift_def_id, line_id, equip_id).
--
-- RECOMMENDED: Use host cron (no pg_cron needed)
--   Crontab: use POSTGRES_USER, POSTGRES_DB from .env (or source .env in cron).
--     0 1 * * * docker exec hmi-db-postgres psql -U admin -d edge_hmi -c "SELECT fn_kpi_sum_calc(CURRENT_DATE - 1);"
--
-- OPTIONAL: pg_cron (if available in image)
--   Requires: shared_preload_libraries = 'pg_cron' in postgresql.conf
--   Standard TimescaleDB images do NOT include pg_cron by default.
--   See README.md for Dockerfile option to build with pg_cron.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- [1. KPI calculation function]
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_kpi_sum_calc(p_calc_date DATE)
RETURNS void
LANGUAGE plpgsql
SET search_path TO core, public
AS $$
DECLARE
  r RECORD;
  v_start TIME;
  v_end TIME;
  win_start TIMESTAMPTZ;
  win_end TIMESTAMPTZ;
  planned_sec FLOAT;
  run_sec FLOAT;
  total_cnt INT;
  good_cnt INT;
  std_ct FLOAT;
  avail FLOAT;
  perf FLOAT;
  qual FLOAT;
  mttr_sec FLOAT;
  mtbf_hr FLOAT;
  failure_cnt BIGINT;
BEGIN
  DELETE FROM kpi_sum WHERE calc_date = p_calc_date;

  FOR r IN
    SELECT DISTINCT sm.shift_def_id, sm.line_id, sm.equip_id
    FROM shift_map sm
    WHERE sm.work_date = p_calc_date AND sm.equip_id IS NOT NULL
  LOOP
    SELECT sc.start_time, sc.end_time INTO v_start, v_end
    FROM shift_cfg sc WHERE sc.id = r.shift_def_id;
    IF NOT FOUND THEN
      CONTINUE;
    END IF;

    win_start := (p_calc_date::date + v_start)::timestamptz;
    win_end   := (p_calc_date::date + v_end)::timestamptz;
    IF v_end <= v_start THEN
      win_end := win_end + INTERVAL '1 day';
    END IF;
    planned_sec := EXTRACT(EPOCH FROM (win_end - win_start));

    -- Run seconds (status_his: status_code = 'Run', overlap with shift window)
    SELECT COALESCE(SUM(
      EXTRACT(EPOCH FROM (
        LEAST(COALESCE(sh.end_time, win_end), win_end) -
        GREATEST(sh.start_time, win_start)
      ))
    ), 0)::FLOAT INTO run_sec
    FROM status_his sh
    WHERE sh.equip_id = r.equip_id
      AND sh.status_code = 'Run'
      AND sh.start_time < win_end
      AND (sh.end_time IS NULL OR sh.end_time > win_start);

    -- Production totals in window
    SELECT COALESCE(SUM(ph.total_cnt), 0)::INT, COALESCE(SUM(ph.good_cnt), 0)::INT
    INTO total_cnt, good_cnt
    FROM prod_his ph
    WHERE ph.equip_id = r.equip_id
      AND ph.time >= win_start AND ph.time < win_end;

    -- Std cycle time (seconds per piece)
    SELECT kc.std_cycle_time INTO std_ct FROM kpi_cfg kc WHERE kc.equip_id = r.equip_id;

    -- Availability
    avail := CASE WHEN planned_sec > 0 THEN LEAST(1.0, run_sec / planned_sec) ELSE 0 END;

    -- Performance (actual / theoretical); theoretical = run_sec / std_ct
    IF run_sec > 0 AND std_ct IS NOT NULL AND std_ct > 0 THEN
      perf := LEAST(1.0, (total_cnt::FLOAT * std_ct) / run_sec);
    ELSE
      perf := 0;
    END IF;

    -- Quality
    qual := CASE WHEN total_cnt > 0 THEN good_cnt::FLOAT / total_cnt ELSE 0 END;

    -- MTTR (avg repair duration in minutes) from maint_his in window
    SELECT AVG(EXTRACT(EPOCH FROM (mh.end_time - mh.start_time)) / 60.0) INTO mttr_sec
    FROM maint_his mh
    WHERE mh.equip_id = r.equip_id
      AND mh.start_time >= win_start AND mh.start_time < win_end
      AND mh.end_time IS NOT NULL;

    -- MTBF (run_sec / failure_count, in hours); failures = alarm_his count in window
    SELECT COUNT(*) INTO failure_cnt
    FROM alarm_his ah
    WHERE ah.equip_id = r.equip_id
      AND ah.time >= win_start AND ah.time < win_end;
    IF run_sec > 0 AND failure_cnt > 0 THEN
      mtbf_hr := (run_sec / 3600.0) / failure_cnt::FLOAT;
    ELSE
      mtbf_hr := NULL;
    END IF;

    -- UPH (Units Per Hour): good_cnt per planned shift hour
    INSERT INTO kpi_sum (
      calc_date, shift_def_id, line_id, equip_id,
      availability, performance, quality, oee, mttr, mtbf, uph
    ) VALUES (
      p_calc_date, r.shift_def_id, r.line_id, r.equip_id,
      avail, perf, qual, avail * perf * qual,
      mttr_sec, mtbf_hr,
      CASE WHEN planned_sec > 0 THEN good_cnt::FLOAT * 3600.0 / planned_sec ELSE NULL END
    );
  END LOOP;
END;
$$;

COMMENT ON FUNCTION fn_kpi_sum_calc(DATE) IS 'Compute KPI (availability, performance, quality, OEE, MTTR, MTBF, UPH) per shift/line/equip for given date and upsert into kpi_sum.';

-- ----------------------------------------------------------------------------
-- [2. pg_cron extension and schedule]
-- ----------------------------------------------------------------------------
-- pg_cron v1.6: schedule(schedule text, command text) 2인자만. DO 블록에서는 text 변수로 전달.
-- 일부 환경(.so vs 스키마 불일치)에서 cron.schedule이 cron.job.active를 참조함 → 없으면 추가.
DO $sched$
DECLARE
    v_jobid BIGINT;
    v_sched text := '0 1 * * *';
    v_cmd   text := 'SELECT core.fn_kpi_sum_calc(CURRENT_DATE - 1)';
BEGIN
    BEGIN
        ALTER TABLE cron.job ADD COLUMN IF NOT EXISTS active boolean NOT NULL DEFAULT true;
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;
    BEGIN
        DELETE FROM cron.job WHERE command LIKE '%fn_kpi_sum_calc%';
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;

    SELECT cron.schedule(v_sched, v_cmd) INTO v_jobid;
    RAISE NOTICE 'pg_cron: KPI daily scheduled (jobid=%).', v_jobid;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'pg_cron registration skipped: %. Use host cron for fn_kpi_sum_calc.', SQLERRM;
END;
$sched$;

-- ----------------------------------------------------------------------------
-- [3. 스케줄 등록 여부 확인]
-- ----------------------------------------------------------------------------
DO $check$
DECLARE
    v_cnt int;
    r RECORD;
BEGIN
    SELECT COUNT(*) INTO v_cnt FROM cron.job WHERE command LIKE '%fn_kpi_sum_calc%';
    RAISE NOTICE 'pg_cron 등록 확인: fn_kpi_sum_calc 관련 job %개', v_cnt;
    IF v_cnt = 0 THEN
        RAISE NOTICE '→ pg_cron에 KPI job 없음. host cron 사용: 0 1 * * * docker exec <컨테이너> psql -U admin -d edge_hmi -c "SELECT core.fn_kpi_sum_calc(CURRENT_DATE - 1);"';
    ELSE
        FOR r IN SELECT jobid, schedule, command FROM cron.job WHERE command LIKE '%fn_kpi_sum_calc%'
        LOOP
            RAISE NOTICE '→ jobid=% schedule=% command=%', r.jobid, r.schedule, r.command;
        END LOOP;
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'pg_cron 등록 확인 실패 (cron.job 없거나 오류): %.', SQLERRM;
END;
$check$;
-- ============================================================================
