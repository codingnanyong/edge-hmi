# 운영 DB → 현재 스키마 마이그레이션 가이드

이 문서는 **이미 데이터가 적재된 PostgreSQL + TimescaleDB** 환경에서, 과거 DDL(짧은 FK 컬럼명·`name`/`sensor_code` 등)을 **현재 `db/sql/init-db.sql` 기준**으로 맞출 때의 절차를 설명합니다.

## 전제

- 스키마 이름은 **`core`** (`search_path`에 `core` 포함).
- TimescaleDB 하이퍼테이블: `measurement`, `equip_status`, `equip_status_his`, `prod_his`.
- 애플리케이션(API)은 마이그레이션 **이후** 배포하는 것을 권장합니다(컬럼명·JSON 필드 불일치 방지).

## 결론: “자동 마이그레이션”을 어떻게 가져갈지

운영에서 필요한 건 (1) **현재 DB가 어떤 DDL이든 감지**해서 (2) **필요한 변경만 적용**하고 (3) **적용 여부를 기록**하는 형태입니다.

이 저장소에서는 아래 구성이 가장 단순하고 실용적입니다.

- **Idempotent SQL migration**: `db/migrations/*.sql`
  - `information_schema`/`pg_catalog`로 기존 상태를 확인하고, 필요한 `ALTER ... RENAME ...`만 실행
  - 여러 번 실행해도 안전(이미 적용된 경우 skip)
- **적용 기록 테이블**: `core.schema_migrations`
  - 마이그레이션이 언제 적용됐는지 DB에 남김
- **실행 스크립트**: `db/scripts/migrate.sh` (기본: `pg_dump` 백업 후 `db/migrations/*.sql` 적용)
  - 배포 파이프라인/운영자가 한 번 실행하면 `db/migrations/`의 SQL을 정렬 순으로 적용

현재 브랜치에는 레거시 → 현재 네이밍 변경을 자동 적용하는 1차 스크립트를 추가해 두었습니다.

- `db/migrations/2026-04-08_legacy_to_current.sql`
- `db/scripts/migrate.sh`

## 변경 요약 (레거시 → 현재)

### 1) FK / 참조 컬럼 이름 (테이블명_id 규칙)

| 테이블 | 레거시 컬럼명 | 현재 컬럼명 |
|--------|---------------|-------------|
| `equip_mst` | `line_id` | `line_mst_id` |
| `sensor_mst` | `equip_id` | `equip_mst_id` |
| `kpi_cfg` | `equip_id` | `equip_mst_id` |
| `alarm_cfg` | `sensor_id` | `sensor_mst_id` |
| `shift_map` | `shift_def_id` | `shift_cfg_id` |
| `shift_map` | `worker_id` | `worker_mst_id` |
| `shift_map` | `line_id` | `line_mst_id` |
| `shift_map` | `equip_id` | `equip_mst_id` |
| `work_order` | `shift_id` | `shift_map_id` |
| `parts_mst` | `equip_id` | `equip_mst_id` |
| `sensor_status` | `sensor_id` | `sensor_mst_id` |
| `measurement` | `equip_id`, `sensor_id` | `equip_mst_id`, `sensor_mst_id` |
| `equip_status` / `equip_status_his` | `equip_id` | `equip_mst_id` |
| `prod_his` | `equip_id` | `equip_mst_id` |
| `defect_his` | `defect_code_id` | `defect_code_mst_id` |
| `alarm_his` | `equip_id`, `alarm_def_id` | `equip_mst_id`, `alarm_cfg_id` |
| `maint_his` | `equip_id`, `maint_def_id`, `part_id`, `worker_id` | `equip_mst_id`, `maint_cfg_id`, `parts_mst_id`, `worker_mst_id` |
| `kpi_sum` | `shift_def_id`, `line_id`, `equip_id` | `shift_cfg_id`, `line_mst_id`, `equip_mst_id` |

이미 현재 이름만 쓰고 있다면, 해당 `RENAME`은 **건너뜁니다**.

### 2) 마스터 표시용 컬럼 이름

| 테이블 | 레거시 | 현재 |
|--------|--------|------|
| `equip_mst` | `name`, `type` | `equip_name`, `equip_type` |
| `sensor_mst` | `sensor_code` | `sensor_name` |
| `worker_mst` | `name` | `worker_name` |

### 3) 제약 이름 (선택)

`sensor_mst` 고유 제약이 예전에 `uq_sensor_equip_code`였다면, 현재 DDL은 **`uq_sensor_equip_name`** 입니다. 컬럼명 변경 후 제약 이름만 맞추려면:

```sql
ALTER TABLE core.sensor_mst RENAME CONSTRAINT uq_sensor_equip_code TO uq_sensor_equip_name;
```

(실제 제약 이름은 `\d core.sensor_mst` 로 확인.)

### 4) 타입: VARCHAR(n) → TEXT

레거시가 `VARCHAR`만 쓰고 있다면, 데이터 유지하며 확장하려면:

```sql
ALTER TABLE core.<table> ALTER COLUMN <col> TYPE TEXT USING <col>::text;
```

대상 컬럼은 레거시 DDL 기준으로 선택합니다. 현재 `init-db.sql`은 문자열 대부분을 `TEXT`로 정의합니다.

### 5) 레거시 pg_dump(예: PostgreSQL 16)와의 구조 차이 — `2026-04-08_legacy_to_current.sql`에서 다루는 범위

일부 배포 DB는 FK 이름만 짧은 형태가 아니라, **현재 `init-db.sql`에만 있는 컬럼 자체가 없습니다.** 마이그레이션 스크립트는 아래를 **idempotent** 하게 보강합니다.

| 영역 | 레거시 예시 | 현재 스키마 | 스크립트 동작 |
|------|-------------|-------------|----------------|
| `line_mst` | `plant_id` / `factory_id` 없음 | 둘 다 NOT NULL | 컬럼 추가 후 `0` / `'UNKNOWN'`으로 채우고 NOT NULL 시도 |
| `sensor_mst` | `mac_address` 없음 | nullable | `ADD COLUMN IF NOT EXISTS` |
| `worker_mst` | `rf_id` 없음 | nullable | `ADD COLUMN IF NOT EXISTS` |
| `shift_cfg` | `work_date` 없음(글로벌 템플릿) | 일자별 행 + UNIQUE | `work_date` nullable 추가; **NULL 행은 운영에서 날짜·코드(S001…) 백필 후** NOT NULL·제약 추가 |
| `work_order` | `shift_id` / `shift_map_id` 없음 | `shift_map_id` NOT NULL + FK | 둘 다 없으면 nullable `shift_map_id` 추가 + 가능 시 FK; **행별 `shift_map` 매핑 후** NOT NULL |

**이 스크립트만으로는 하지 않는 것(데이터·Timescale 제약 의존):** 하이퍼테이블 PK 형태 변경(예: `equip_status`에 `equip_mst_id` 포함), `shift_cfg`의 `chk_shift_cfg_shift_name`·`(work_date, shift_name)` 유일성, `work_order.shift_map_id` 최종 NOT NULL — 필요 시 별도 절차·다운타임 계획이 필요합니다.

레거시 DDL을 참고용으로 남기려면 저장소에 `db/migrations/reference/` 등에 덤프를 두고 diff 하는 방식을 권장합니다.

함수 `fn_kpi_sum_calc` / `fn_sync_equip_status_from_his`는 컬럼 rename 이후 **반드시** 현재 `db/sql/kpi-scheduler.sql`, `db/sql/equip-status-fn.sql`로 교체합니다.

---

## 사전 준비

1. **풀 백업** (논리 덤프 권장):

   ```bash
   pg_dump -h <host> -U <user> -d <db> -Fc -f edge_hmi_pre_migration_$(date +%Y%m%d).dump
   ```

2. **점검 윈도우**: 쓰기 트래픽(API·수집기)을 줄이거나 잠시 중지하면 트랜잭션·락이 단순해집니다.

3. **현재 컬럼 확인** (레거시만 골라 실행):

   ```sql
   SET search_path TO core, public;
   SELECT table_name, column_name
   FROM information_schema.columns
   WHERE table_schema = 'core'
     AND table_name IN (
       'equip_mst', 'sensor_mst', 'worker_mst', 'shift_map', 'work_order',
       'measurement', 'equip_status', 'equip_status_his', 'prod_his',
       'defect_his', 'alarm_his', 'maint_his', 'kpi_sum', 'alarm_cfg',
       'kpi_cfg', 'parts_mst', 'sensor_status'
     )
   ORDER BY table_name, ordinal_position;
   ```

---

## 마이그레이션 실행 순서

### (권장) 자동 적용

운영/배포 환경에서 `psql`만 있으면 아래처럼 실행할 수 있습니다.

```bash
# 1) DB 접속 URL로 실행 (선행: pg_dump 백업 → db/backups/pre_migrate_*.dump)
DB_URL="postgresql://<user>:<pass>@<host>:5432/<db>" ./db/scripts/migrate.sh

# 또는 2) psql 환경변수 사용
PGHOST=<host> PGUSER=<user> PGPASSWORD=<pass> PGDATABASE=<db> ./db/scripts/migrate.sh

# CI/로컬에서만 백업 생략 (비권장)
# SKIP_BACKUP=1 ./db/scripts/migrate.sh
```

이 방식은 **DB가 레거시든 최신이든** `db/migrations/*.sql`이 상태를 감지해서 필요한 변경만 적용합니다. `init-db.sql` 전체가 아니라 **변경분만** 들어 있는 SQL이 `migrations/`에 있습니다.

### 배포 자동화에 넣는 추천 형태

가장 흔한 방식은 **API/수집기 컨테이너를 올리기 전에** (즉, DB가 idle일 때) “마이그레이션 전용 job/단계”를 한 번 실행하는 것입니다.

- 배포 파이프라인 예시(개념):
  - `./db/scripts/migrate.sh` 실행 (기본 포함: `pg_dump -Fc` 백업 후 마이그레이션; 실패 시 stderr에 `pg_restore` 예시)
  - 또는 별도 백업 후 동일 스크립트 (`SKIP_BACKUP=1`은 CI 등에서만)
  - `psql -f db/sql/equip-status-fn.sql` (트리거/함수 최신화)
  - `psql -f db/sql/kpi-scheduler.sql` (집계 함수 최신화)
  - API/웹 배포

이 순서가 좋은 이유는, **스키마가 바뀌는 동안 애플리케이션이 옛 컬럼명으로 쿼리하는 순간**을 없애기 쉽기 때문입니다.

PostgreSQL에서는 **`ALTER TABLE ... RENAME COLUMN`** 시 참조하는 FK 제약은 컬럼에 따라 함께 따라갑니다. 별도로 자식 테이블 FK를 끊을 필요는 대개 없습니다.

### 1. 트랜잭션에서 컬럼 이름 일괄 변경

아래는 **레거시 컬럼이 아직 존재한다고 가정**한 예시입니다. 이미 새 이름이면 해당 줄은 제거하거나, 예외가 나면 건너뜁니다.

```sql
BEGIN;
SET search_path TO core, public;

-- equip_mst
ALTER TABLE equip_mst RENAME COLUMN line_id TO line_mst_id;
ALTER TABLE equip_mst RENAME COLUMN name TO equip_name;
ALTER TABLE equip_mst RENAME COLUMN type TO equip_type;

-- sensor_mst
ALTER TABLE sensor_mst RENAME COLUMN equip_id TO equip_mst_id;
ALTER TABLE sensor_mst RENAME COLUMN sensor_code TO sensor_name;

-- worker_mst
ALTER TABLE worker_mst RENAME COLUMN name TO worker_name;

-- kpi_cfg, alarm_cfg, parts_mst
ALTER TABLE kpi_cfg RENAME COLUMN equip_id TO equip_mst_id;
ALTER TABLE alarm_cfg RENAME COLUMN sensor_id TO sensor_mst_id;
ALTER TABLE parts_mst RENAME COLUMN equip_id TO equip_mst_id;

-- shift_map
ALTER TABLE shift_map RENAME COLUMN shift_def_id TO shift_cfg_id;
ALTER TABLE shift_map RENAME COLUMN worker_id TO worker_mst_id;
ALTER TABLE shift_map RENAME COLUMN line_id TO line_mst_id;
ALTER TABLE shift_map RENAME COLUMN equip_id TO equip_mst_id;

-- work_order
ALTER TABLE work_order RENAME COLUMN shift_id TO shift_map_id;

-- sensor_status
ALTER TABLE sensor_status RENAME COLUMN sensor_id TO sensor_mst_id;

-- hypertables
ALTER TABLE measurement RENAME COLUMN equip_id TO equip_mst_id;
ALTER TABLE measurement RENAME COLUMN sensor_id TO sensor_mst_id;
ALTER TABLE equip_status RENAME COLUMN equip_id TO equip_mst_id;
ALTER TABLE equip_status_his RENAME COLUMN equip_id TO equip_mst_id;
ALTER TABLE prod_his RENAME COLUMN equip_id TO equip_mst_id;

-- history / summary
ALTER TABLE defect_his RENAME COLUMN defect_code_id TO defect_code_mst_id;
ALTER TABLE alarm_his RENAME COLUMN equip_id TO equip_mst_id;
ALTER TABLE alarm_his RENAME COLUMN alarm_def_id TO alarm_cfg_id;
ALTER TABLE maint_his RENAME COLUMN equip_id TO equip_mst_id;
ALTER TABLE maint_his RENAME COLUMN maint_def_id TO maint_cfg_id;
ALTER TABLE maint_his RENAME COLUMN part_id TO parts_mst_id;
ALTER TABLE maint_his RENAME COLUMN worker_id TO worker_mst_id;
ALTER TABLE kpi_sum RENAME COLUMN shift_def_id TO shift_cfg_id;
ALTER TABLE kpi_sum RENAME COLUMN line_id TO line_mst_id;
ALTER TABLE kpi_sum RENAME COLUMN equip_id TO equip_mst_id;

COMMIT;
```

실패 시 `ROLLBACK;` 후 백업에서 원인을 확인합니다.

### 2. TimescaleDB 압축 세그먼트 설정 갱신

`measurement`에 압축 정책이 있고, 세그먼트가 예전 컬럼명을 쓰고 있으면 **이름 변경 후** 다음을 실행합니다.

```sql
SET search_path TO core, public;
ALTER TABLE measurement SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'equip_mst_id,sensor_mst_id'
);
```

(기존에 `compress_orderby` 등을 쓰고 있다면 `init-db.sql` [5. TimescaleDB Policies]와 동일하게 맞춥니다.)

### 3. 함수·트리거 재배포

컬럼명을 바꾼 뒤에는 PL/pgSQL 본문이 새 이름을 참조하도록 **저장 프로시저·트리거 SQL을 다시 적용**합니다.

권장 적용 순서(프로젝트 기준):

1. `db/sql/equip-status-fn.sql` (`fn_sync_equip_status_from_his`, `equip_mst_id` 사용)
2. `db/sql/kpi-scheduler.sql` (`fn_kpi_sum_calc` — `shift_cfg_id`, `line_mst_id`, `equip_mst_id` 등)
3. `db/sql/shift-cfg-daily.sql` (`fn_shift_cfg_daily` — 보통 컬럼 리네임과 무관하지만, 운영 정책에 맞게 최신본 유지)

```bash
psql -h <host> -U <user> -d <db> -v ON_ERROR_STOP=1 -f db/sql/equip-status-fn.sql
psql -h <host> -U <user> -d <db> -v ON_ERROR_STOP=1 -f db/sql/kpi-scheduler.sql
# 필요 시
psql -h <host> -U <user> -d <db> -f db/sql/shift-cfg-daily.sql
```

### 4. (선택) 제약·인덱스·코멘트

- `sensor_mst` UNIQUE 제약 이름을 `uq_sensor_equip_name`으로 맞춤(위 참고).
- `init-db.sql`의 `CREATE INDEX IF NOT EXISTS` 중 **아직 없는 인덱스**만 선별 실행(이미 같은 인덱스가 있으면 생략).

### 5. 애플리케이션 배포

- **API·웹**을 현재 브랜치 기준으로 배포해 요청/응답 필드명(`equip_name`, `sensor_name`, `*_mst_id` 등)을 일치시킵니다.

---

## 검증 쿼리 예시

```sql
SET search_path TO core, public;

-- FK 컬럼 샘플
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'core' AND table_name = 'measurement'
ORDER BY ordinal_position;

-- 하이퍼테이블 여부
SELECT * FROM timescaledb_information.hypertables
WHERE hypertable_schema = 'core';

-- 적용된 마이그레이션 확인
SELECT * FROM core.schema_migrations ORDER BY applied_at DESC;

-- 최근 measurement 1건
SELECT * FROM measurement ORDER BY time DESC LIMIT 1;
```

---

## 롤백

- 마이그레이션 직전 **물리/논리 백업**이 기준입니다.
- `RENAME`만 수행했다면 역으로 다시 `RENAME`할 수 있지만, 운영 중 신규 데이터가 쌓인 뒤에는 백업 복원이 더 안전합니다.

```bash
pg_restore -h <host> -U <user> -d <db> --clean --if-exists edge_hmi_pre_migration_YYYYMMDD.dump
```

(덤프 형식에 따라 `pg_restore` / `psql` 중 선택.)

---

## 주의사항

1. **부분 적용 금지**: API는 새 컬럼명만 쓰는데 DB만 옛 이름이면 장애가 납니다. DB 마이그레이션 완료 후 API를 올리거나, 짧은 점검 윈도우에서 동시 전환하세요.
2. **레거시 스키마 차이**: 실제 운영 DDL이 이 문서와 다르면(예: 테이블·컬럼 없음), `information_schema`로 확인한 뒤 스크립트를 수정합니다.
3. **대용량 `measurement`**: `RENAME COLUMN`은 메타데이터 수준이라 일반적으로 빠르지만, 트랜잭션 시간·락은 환경별로 확인하세요.
4. **pg_cron**: `kpi-scheduler.sql` / `shift-cfg-daily.sql` 안의 스케줄 재등록은 이미지·권한에 따라 실패할 수 있습니다. 실패 시 호스트 cron으로 동일 SQL만 호출해도 됩니다.

---

## 참고 파일

- 기준 DDL: `db/sql/init-db.sql`
- 트리거: `db/sql/equip-status-fn.sql`
- KPI 함수·cron: `db/sql/kpi-scheduler.sql`
- 교대 선적재: `db/sql/shift-cfg-daily.sql`

- 자동 마이그레이션: `db/migrations/2026-04-08_legacy_to_current.sql`
- 실행 스크립트: `db/scripts/migrate.sh`

문서 버전: 현재 저장소의 `init-db.sql` 및 관련 SQL과 동기화되어 있습니다. DDL이 바뀌면 이 문서의 매핑 표도 함께 갱신하세요.
