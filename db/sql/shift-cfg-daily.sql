-- ============================================================================
-- Shift_cfg 일일 선적재 + Scheduler
-- ============================================================================
-- Prereq: init-db.sql — shift_cfg UNIQUE (work_date, shift_name),
--         core.shift_sat_ext_plan (토요일 5HOUR vs 8HOUR; 데이터는 이 파일이 아님)
-- Run order: init-db → equip-status-fn → kpi-scheduler → 이 파일(03)
--
-- 내용: core.fn_shift_cfg_daily() 정의 + 교대용 pg_cron 1개 등록.
-- KPI 집계·스케줄은 kpi-scheduler.sql 참고.
--
-- ■ core.shift_sat_ext_plan — Airflow 등으로 주기 적재 (운영 파이프라인)
--   이 SQL은 테이블에 INSERT 하지 않는다. 토요일 plan_date 행은 배치가 미리 넣어 두고,
--   매일 밤 본 함수가 읽어서 shift_cfg 를 채운다.
--   컬럼 의미:
--     plan_date — 대상 토요일(내일 날짜와 일치해야 매칭)
--     shift_cd  — 5HOUR | 8HOUR (슬롯 패턴; 상세 시간은 함수 내 매핑)
--     version_id — 출처/문서 버전 추적용(선택)
--     plan_date 당 최신 updated_at 행이 우선.
--
-- ■ 적용 규칙 (내일 work_date 기준 ISO 요일)
--   월~목: 1Shift 06:30–14:30 | 2Shift 14:30–22:30 | 3Shift 22:30–06:30(익일)
--   금:    1Shift 06:30–15:00 | 2Shift 15:00–23:00 | 3Shift 22:30–06:30(익일)
--   토:    shift_sat_ext_plan 에 해당 plan_date 행이 있으면 shift_cd(5HOUR|8HOUR) 매핑
--        없거나 매핑 실패 시 기본 토요일 규칙
--        (1Shift 06:30–11:30 | 2Shift 11:30–16:30 | 3Shift 16:30–21:30)
--   일(7): INSERT 안 함 (미운영)
--
-- 호스트 cron (pg_cron 없을 때):
--   0 23 * * * docker exec <c> psql -U admin -d edge_hmi -c "SELECT core.fn_shift_cfg_daily();"
--
-- pg_cron (성공 시):
--   0 23 * * * → SELECT core.fn_shift_cfg_daily();  (서버 TimeZone 기준)
-- ============================================================================

SET search_path TO core, public;

-- ----------------------------------------------------------------------------
-- [1] 내일 shift_cfg 행 선적재 (테이블 DDL은 init-db.sql)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION core.fn_shift_cfg_daily()
RETURNS void
LANGUAGE plpgsql
SET search_path TO core, public
AS $$
DECLARE
    v_work_date DATE := (CURRENT_DATE + INTERVAL '1 day')::date;
    v_dow INT := EXTRACT(ISODOW FROM (CURRENT_DATE + INTERVAL '1 day'))::int;
    v_pattern TEXT; -- '5HOUR' | '8HOUR' from shift_sat_ext_plan.shift_cd
    v_ins INT;
BEGIN
    -- 일요일 미운영
    IF v_dow = 7 THEN
        RETURN;
    END IF;

    -- 월~금: 고정 규칙
    IF v_dow BETWEEN 1 AND 5 THEN
        INSERT INTO shift_cfg (work_date, shift_name, start_time, end_time)
        SELECT
            v_work_date,
            s.shift_name,
            s.start_time,
            s.end_time
        FROM (
            SELECT 'S001' AS shift_name,
                   TIME '06:30' AS start_time,
                   CASE WHEN v_dow BETWEEN 1 AND 4 THEN TIME '14:30' ELSE TIME '15:00' END AS end_time
            UNION ALL
            SELECT 'S002',
                   CASE WHEN v_dow BETWEEN 1 AND 4 THEN TIME '14:30' ELSE TIME '15:00' END,
                   CASE WHEN v_dow BETWEEN 1 AND 4 THEN TIME '22:30' ELSE TIME '23:00' END
            UNION ALL
            SELECT 'S003', TIME '22:30', TIME '06:30'
        ) s
        ON CONFLICT (work_date, shift_name) DO UPDATE
        SET start_time = EXCLUDED.start_time,
            end_time = EXCLUDED.end_time;
        RETURN;
    END IF;

    -- 토요일: shift_sat_ext_plan(운영에서 Airflow 등으로 선적재)에서 5HOUR / 8HOUR 선택
    SELECT upper(btrim(p.shift_cd))
    INTO v_pattern
    FROM shift_sat_ext_plan p
    WHERE p.plan_date = v_work_date
    ORDER BY p.updated_at DESC
    LIMIT 1;

    IF v_pattern IS NOT NULL THEN
        INSERT INTO shift_cfg (work_date, shift_name, start_time, end_time)
        SELECT
            v_work_date,
            m.shift_name,
            m.start_time,
            m.end_time
        FROM (
            -- 5HOUR 패턴
            SELECT '5HOUR'::text AS pat, 'S001'::text AS shift_name, TIME '06:30' AS start_time, TIME '11:29' AS end_time
            UNION ALL SELECT '5HOUR', 'S002', TIME '11:30', TIME '16:29'
            UNION ALL SELECT '5HOUR', 'S003', TIME '16:30', TIME '06:29'
            -- 8HOUR 패턴
            UNION ALL SELECT '8HOUR', 'S001', TIME '06:30', TIME '14:29'
            UNION ALL SELECT '8HOUR', 'S002', TIME '14:30', TIME '22:29'
            UNION ALL SELECT '8HOUR', 'S003', TIME '22:30', TIME '06:29'
        ) m
        WHERE m.pat = v_pattern
        ON CONFLICT (work_date, shift_name) DO UPDATE
        SET start_time = EXCLUDED.start_time,
            end_time = EXCLUDED.end_time;

        GET DIAGNOSTICS v_ins = ROW_COUNT;
        IF v_ins > 0 THEN
            RETURN;
        END IF;
        RAISE WARNING 'shift_sat_ext_plan shift_cd=% for % did not match 5HOUR/8HOUR mapping. Fallback to default Saturday rules.', v_pattern, v_work_date;
    END IF;

    -- 토요일 fallback (plan 없음 또는 매핑 0건)
    INSERT INTO shift_cfg (work_date, shift_name, start_time, end_time)
    SELECT
        v_work_date,
        s.shift_name,
        s.start_time,
        s.end_time
    FROM (
        SELECT 'S001'::text AS shift_name, TIME '06:30' AS start_time, TIME '11:30' AS end_time
        UNION ALL SELECT 'S002', TIME '11:30', TIME '16:30'
        UNION ALL SELECT 'S003', TIME '16:30', TIME '21:30'
    ) s
    ON CONFLICT (work_date, shift_name) DO UPDATE
    SET start_time = EXCLUDED.start_time,
        end_time = EXCLUDED.end_time;
END;
$$;

COMMENT ON FUNCTION core.fn_shift_cfg_daily() IS
'Tomorrow shift_cfg: Mon-Fri fixed; Saturday reads shift_sat_ext_plan (filled by Airflow/etc.), 5HOUR vs 8HOUR; else default Sat; Sunday skipped.';

-- ----------------------------------------------------------------------------
-- [2] pg_cron: 교대 선적재만 등록
-- ----------------------------------------------------------------------------
DO $sched$
DECLARE
    v_jobid BIGINT;
    v_sched text := '30 23 * * *';
    v_cmd   text := 'SELECT core.fn_shift_cfg_daily()';
BEGIN
    BEGIN
        ALTER TABLE cron.job ADD COLUMN IF NOT EXISTS active boolean NOT NULL DEFAULT true;
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;
    BEGIN
        DELETE FROM cron.job WHERE command LIKE '%fn_shift_cfg_daily%';
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;

    SELECT cron.schedule(v_sched, v_cmd) INTO v_jobid;
    RAISE NOTICE 'pg_cron: shift_cfg daily scheduled (jobid=%).', v_jobid;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'pg_cron shift registration skipped: %. Use host cron.', SQLERRM;
END;
$sched$;

-- ----------------------------------------------------------------------------
-- [3] 교대 스케줄 등록 확인
-- ----------------------------------------------------------------------------
DO $check$
DECLARE
    v_cnt int;
    r RECORD;
BEGIN
    SELECT COUNT(*) INTO v_cnt FROM cron.job WHERE command LIKE '%fn_shift_cfg_daily%';
    RAISE NOTICE 'pg_cron 등록 확인: fn_shift_cfg_daily job %개', v_cnt;
    IF v_cnt = 0 THEN
        RAISE NOTICE '→ pg_cron에 shift job 없음. host cron: SELECT core.fn_shift_cfg_daily();';
    ELSE
        FOR r IN SELECT jobid, schedule, command FROM cron.job WHERE command LIKE '%fn_shift_cfg_daily%'
        LOOP
            RAISE NOTICE '→ jobid=% schedule=% command=%', r.jobid, r.schedule, r.command;
        END LOOP;
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'pg_cron shift 확인 실패: %.', SQLERRM;
END;
$check$;
