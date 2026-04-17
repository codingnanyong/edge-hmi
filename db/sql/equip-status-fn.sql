-- ============================================================================
-- Equipment Status Interval Sync
-- ============================================================================
-- Maintains core.equip_status (interval table) from core.equip_status_his
-- (raw polled events). This file is separate from init-db.sql so that
-- functions/triggers can be evolved independently of base DDL.
--
-- 협의사항: equip_status_his는 매초 적재(폴링)한다.
-- equip_status에는 "상태가 바뀔 때만" 쓰기:
--   - 상태 변경 시: 기존 구간 UPDATE(end_time 설정) + 새 구간 INSERT
--   - 동일 상태 연속 시: equip_status에는 INSERT/UPDATE 없음
-- ============================================================================

SET search_path TO core, public;

-- 1. Trigger function: 상태 변경 시에만 equip_status INSERT/UPDATE
--   - 이전 구간 없음 → INSERT (새 구간 시작)
--   - 이전과 status_code 다름 → UPDATE(이전 구간 end_time) + INSERT(새 구간)
--   - 이전과 status_code 같음 → 아무 쓰기 없음 (매초 적재 시 대부분 이 경우)
CREATE OR REPLACE FUNCTION fn_sync_equip_status_from_his()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_last_id BIGINT;
    v_last_status text;
    v_last_start TIMESTAMPTZ;
BEGIN
    -- Find the latest interval for this equipment
    SELECT id, status_code, start_time
    INTO v_last_id, v_last_status, v_last_start
    FROM equip_status
    WHERE equip_mst_id = NEW.equip_mst_id
    ORDER BY start_time DESC
    LIMIT 1;

    -- First status for this equipment
    IF v_last_id IS NULL THEN
        INSERT INTO equip_status (equip_mst_id, status_code, start_time)
        VALUES (NEW.equip_mst_id, NEW.status_code, NEW.capture_time);
        RETURN NEW;
    END IF;

    -- 상태 동일: equip_status에 INSERT/UPDATE 하지 않음
    IF v_last_status IS NOT DISTINCT FROM NEW.status_code THEN
        RETURN NEW;
    END IF;

    -- Close previous interval
    UPDATE equip_status
    SET end_time = NEW.capture_time
    WHERE id = v_last_id;

    -- Start new interval
    INSERT INTO equip_status (equip_mst_id, status_code, start_time)
    VALUES (NEW.equip_mst_id, NEW.status_code, NEW.capture_time);

    RETURN NEW;
END;
$$;

-- 2. Trigger definition
DROP TRIGGER IF EXISTS trg_equip_status_his_sync ON equip_status_his;
CREATE TRIGGER trg_equip_status_his_sync
AFTER INSERT ON equip_status_his
FOR EACH ROW
EXECUTE FUNCTION fn_sync_equip_status_from_his();

