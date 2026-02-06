-- ============================================================================
-- 더미 데이터 전부 삭제 (FK 순서 준수)
-- Run from test/: docker exec -i hmi-db-postgres psql -U admin -d edge_hmi -f - < sql/00-cleanup.sql
-- ============================================================================

SET search_path TO core, public;

DELETE FROM defect_his;
DELETE FROM kpi_sum;
DELETE FROM shift_map;
DELETE FROM maint_his;
DELETE FROM alarm_his;
DELETE FROM prod_his;
DELETE FROM status_his;
DELETE FROM measurement;
DELETE FROM kpi_cfg;
DELETE FROM sensor_mst;
DELETE FROM alarm_cfg;
DELETE FROM maint_cfg;
DELETE FROM worker_mst;
DELETE FROM shift_cfg;
DELETE FROM equip_mst;
DELETE FROM parts_mst;
DELETE FROM line_mst;
DELETE FROM work_order;
DELETE FROM defect_code_mst;
