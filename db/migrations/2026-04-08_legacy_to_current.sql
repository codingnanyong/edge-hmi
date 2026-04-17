-- ============================================================================
-- Migration: legacy deployed DDL -> current init-db.sql naming
-- Date: 2026-04-08
--
-- Goals:
-- - Add columns present in current init-db.sql but absent in typical legacy DDL
--   (e.g. line_mst.plant_id/factory_id, work_order.shift_map_id, sensor_mst.mac_address,
--   worker_mst.rf_id, shift_cfg.work_date) — see MIGRATION-LEGACY-TO-CURRENT.md section 5
-- - Rename legacy FK/display columns where legacy names differ (e.g. shift_def_id -> shift_cfg_id).
--   Master-table FKs use short *_id in unreleased DBs; folding *_mst_id -> *_id is out of scope here.
-- - Rename master display columns (equip_mst.name -> equip_name, etc.)
-- - Update dependent indexes/constraints when needed
-- - Refresh TimescaleDB compression segment-by for measurement
-- - Record migration in core.schema_migrations
--
-- Not handled here (high risk / data-dependent): hypertable PRIMARY KEY shape changes,
-- shift_cfg CHECK/UNIQUE vs legacy shift_name values, NOT NULL on work_order.shift_map_id
-- after backfill — operators must follow the doc.
--
-- This script is designed to be IDEMPOTENT:
-- - Safe to run multiple times
-- - Skips changes if columns/constraints already in the target form
--
-- No explicit BEGIN/COMMIT: avoids "there is no transaction in progress" when a GUI runs
-- one statement at a time. For atomic apply in psql: psql -v ON_ERROR_STOP=1 -1 -f this_file.sql
-- ============================================================================

SET search_path TO core, public;

-- ---------------------------------------------------------------------------
-- [0] Migration bookkeeping
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS core.schema_migrations (
  id TEXT PRIMARY KEY,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  checksum TEXT,
  note TEXT
);

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM core.schema_migrations WHERE id = '2026-04-08_legacy_to_current') THEN
    RAISE NOTICE 'schema_migrations: already applied (2026-04-08_legacy_to_current).';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- [0.5] Structural gaps vs legacy pg_dump (additive, idempotent)
--       Run BEFORE column renames so FK targets (e.g. shift_map) still match names.
-- ---------------------------------------------------------------------------

-- line_mst: plant_id / factory_id (legacy dump often has only process_type, line_code, line_name)
ALTER TABLE core.line_mst ADD COLUMN IF NOT EXISTS plant_id INTEGER;
ALTER TABLE core.line_mst ADD COLUMN IF NOT EXISTS factory_id TEXT;
UPDATE core.line_mst SET plant_id = 0 WHERE plant_id IS NULL;
UPDATE core.line_mst SET factory_id = 'UNKNOWN' WHERE factory_id IS NULL;
DO $$
BEGIN
  ALTER TABLE core.line_mst ALTER COLUMN plant_id SET NOT NULL;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'line_mst.plant_id NOT NULL skipped: %', SQLERRM;
END $$;
DO $$
BEGIN
  ALTER TABLE core.line_mst ALTER COLUMN factory_id SET NOT NULL;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'line_mst.factory_id NOT NULL skipped: %', SQLERRM;
END $$;

-- sensor_mst / worker_mst: optional columns in current schema
ALTER TABLE core.sensor_mst ADD COLUMN IF NOT EXISTS mac_address TEXT;
ALTER TABLE core.worker_mst ADD COLUMN IF NOT EXISTS rf_id TEXT;

-- shift_sat_ext_plan: Saturday 5HOUR vs 8HOUR pattern from external data (align with init-db.sql)
CREATE TABLE IF NOT EXISTS core.shift_sat_ext_plan (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  version_id TEXT NOT NULL,
  plan_date DATE NOT NULL,
  shift_cd TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_shift_sat_ext_plan_shift_cd CHECK (upper(btrim(shift_cd)) IN ('5HOUR', '8HOUR'))
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_shift_sat_ext_plan_date ON core.shift_sat_ext_plan (plan_date);

-- shift_cfg: per-calendar-date model (legacy may be global templates without work_date)
ALTER TABLE core.shift_cfg ADD COLUMN IF NOT EXISTS work_date DATE;
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' AND table_name = 'shift_cfg' AND column_name = 'work_date'
  ) AND EXISTS (SELECT 1 FROM core.shift_cfg WHERE work_date IS NULL) THEN
    RAISE NOTICE 'shift_cfg.work_date has NULL rows; backfill dates then SET NOT NULL and add uq_shift_cfg_work_date_shift_name (see doc).';
  END IF;
END $$;

-- work_order: legacy often has no shift column; intermediate DBs may have shift_id (renamed below)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' AND table_name = 'work_order'
      AND column_name IN ('shift_map_id', 'shift_id')
  ) THEN
    ALTER TABLE core.work_order ADD COLUMN shift_map_id INTEGER;
    RAISE NOTICE 'work_order: added nullable shift_map_id; backfill from shift_map, then NOT NULL + FK per doc.';
  END IF;
END $$;

-- Helper: conditionally rename a column if old exists and new does not
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT *
    FROM (VALUES
      -- Master display names
      ('equip_mst','name','equip_name'),
      ('equip_mst','type','equip_type'),
      ('sensor_mst','sensor_code','sensor_name'),
      ('worker_mst','name','worker_name'),

      -- Legacy DDL naming fixes (not *_mst_id -> *_id; unreleased DBs already use equip_id, line_id, …)
      ('shift_map','shift_def_id','shift_cfg_id'),
      ('work_order','shift_id','shift_map_id'),
      ('alarm_his','alarm_def_id','alarm_cfg_id'),
      ('maint_his','maint_def_id','maint_cfg_id'),
      ('kpi_sum','shift_def_id','shift_cfg_id')
    ) AS v(table_name, old_col, new_col)
  LOOP
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='core' AND table_name=r.table_name AND column_name=r.old_col
    )
    AND NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='core' AND table_name=r.table_name AND column_name=r.new_col
    )
    THEN
      EXECUTE format('ALTER TABLE core.%I RENAME COLUMN %I TO %I', r.table_name, r.old_col, r.new_col);
      RAISE NOTICE 'Renamed %.% -> %', r.table_name, r.old_col, r.new_col;
    END IF;
  END LOOP;
END $$;

-- FK work_order.shift_map_id -> shift_map(id) after renames (shift_id may have become shift_map_id)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'core' AND table_name = 'work_order' AND column_name = 'shift_map_id'
  )
  AND EXISTS (
    SELECT 1 FROM pg_class t
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname = 'core' AND t.relname = 'shift_map'
  )
  AND NOT EXISTS (
    SELECT 1
    FROM pg_constraint c
    JOIN pg_class rel ON rel.oid = c.conrelid
    JOIN pg_namespace rn ON rn.oid = rel.relnamespace
    JOIN pg_class frel ON frel.oid = c.confrelid
    JOIN pg_namespace fn ON fn.oid = frel.relnamespace
    WHERE c.contype = 'f'
      AND rn.nspname = 'core' AND rel.relname = 'work_order'
      AND fn.nspname = 'core' AND frel.relname = 'shift_map'
  )
  THEN
    ALTER TABLE core.work_order
      ADD CONSTRAINT work_order_shift_map_id_fkey
      FOREIGN KEY (shift_map_id) REFERENCES core.shift_map(id) ON DELETE RESTRICT;
    RAISE NOTICE 'Added FK work_order.shift_map_id -> shift_map(id).';
  END IF;
EXCEPTION
  WHEN duplicate_object THEN
    NULL;
  WHEN OTHERS THEN
    RAISE WARNING 'work_order shift_map_id FK skipped: %', SQLERRM;
END $$;

-- ---------------------------------------------------------------------------
-- [1] sensor_mst unique constraint rename (optional)
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname='core' AND t.relname='sensor_mst' AND c.conname='uq_sensor_equip_code'
  )
  AND NOT EXISTS (
    SELECT 1
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname='core' AND t.relname='sensor_mst' AND c.conname='uq_sensor_equip_name'
  )
  THEN
    ALTER TABLE core.sensor_mst RENAME CONSTRAINT uq_sensor_equip_code TO uq_sensor_equip_name;
    RAISE NOTICE 'Renamed constraint uq_sensor_equip_code -> uq_sensor_equip_name';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- [2] TimescaleDB compression settings for measurement
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='core' AND c.relname='measurement') THEN
    -- Ensure segment-by uses the new column names.
    EXECUTE $q$
      ALTER TABLE core.measurement SET (
        timescaledb.compress,
        timescaledb.compress_segmentby = 'equip_id,sensor_id'
      )
    $q$;
  END IF;
EXCEPTION WHEN OTHERS THEN
  -- Compression options vary by Timescale version/config; don't fail the whole migration.
  RAISE WARNING 'Skipping measurement compress settings update: %', SQLERRM;
END $$;

-- ---------------------------------------------------------------------------
-- [3] Record applied migration (if not already)
-- ---------------------------------------------------------------------------
INSERT INTO core.schema_migrations (id, checksum, note)
SELECT
  '2026-04-08_legacy_to_current',
  NULL,
  'Additive columns (line_mst plant/factory, shift_cfg.work_date nullable, work_order.shift_map_id, mac_address, rf_id) + rename legacy display/FK names (equip_name, shift_cfg_id, …); not *_mst_id -> *_id'
WHERE NOT EXISTS (SELECT 1 FROM core.schema_migrations WHERE id = '2026-04-08_legacy_to_current');

