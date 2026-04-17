# 교대 규칙: 고정(월~금) vs 토요일(외부 기준)

## 현재 (`fn_shift_cfg_daily`)

- **내일(`work_date`)** 기준 ISO 요일로 `shift_cfg` 행을 넣습니다.
- **월~금(`dow` 1~5)** 및 **토(`dow` 6`)** 는 함수 안의 `CASE`로 **고정** 처리합니다.
- **일요일(`dow` 7`)** 은 **생산/교대 미사용**으로 두고, **INSERT 하지 않습니다.**

### 고정 규칙 요약

| 요일 | 1Shift | 2Shift | 3Shift |
|------|--------|--------|--------|
| 월~목 | 06:30–14:30 | 14:30–22:30 | 22:30–06:30(익일) |
| 금 | 06:30–15:00 | 15:00–23:00 | 22:30–06:30(익일) |
| 토(기본) | 06:30–11:30 | 11:30–16:30 | 16:30–21:30 |

**토요일**은 아래 **외부 기준표**가 있으면, 그날 `PLAN_DATE` / `SHIFT_CD` 에 맞춰 **별도 적재·오버라이드**하는 방향을 권장합니다. (함수 내부 하드코딩과 동기화하거나, 외부만 신뢰.)

---

## 토요일 외부 기준 (예: MES / OSP)

외부에서 읽어 올 데이터는 **일 단위 계획 + 교대 유형 코드** 형태로 두면 됩니다.

### 예시 컬럼 (스크린샷 기준)

| 컬럼 | 예시 | 설명 |
|------|------|------|
| `VERSION_ID` | `OSP-260313-M-003` | 문서/계획 버전 (추적용) |
| `PLAN_DATE` | `20260314` | **적용 일자** (YYYYMMDD, 토요일이면 해당 토요일) |
| `SHIFT_CD` | `5HOUR` | 그날 교대 패턴 코드 |

- `PLAN_DATE` = `shift_cfg.work_date` 와 맞추면 됨 (DB에는 `date` 타입으로 변환: `to_date(PLAN_DATE::text, 'YYYYMMDD')`).
- `shift_cfg.shift_name` 은 DB 제약상 **`S001`,`S002`,`S003`만 사용**합니다.
- `SHIFT_CD` 예시(토요일):
  - **`5HOUR`**: S001 06:30–11:29, S002 11:30–16:29, S003 16:30–06:29(다음날)
  - **`8HOUR`**: S001 06:30–14:29, S002 14:30–22:29, S003 22:30–06:29(다음날)
  - 향후 `휴무` 같은 코드를 추가하면 **`SHIFT_CD` → (S001~S003 start/end)** 매핑만 확장하면 됩니다.

---

## 연동 패턴 (권장 순)

### 1) `shift_cfg`에만 반영 (가장 단순)

- 외부 배치가 `PLAN_DATE`(토요일)에 대해 **`shift_cfg` 를 `UPSERT`** (`ON CONFLICT (work_date, shift_name)`).
- Edge DB의 `fn_shift_cfg_daily` 는 **월~금만** 채우고, **토요일 행은 넣지 않게** 바꾸거나, 토요일은 **항상 외부 job이 덮어쓰기** (실행 순서: 선행 외부 → 또는 함수에서 토 제외).

**장점:** 구현 빠름.  
**단점:** `SHIFT_CD` 해석 로직이 애플리케이션/배치 쪽에 있음.

---

### 2) Edge DB에 스테이징 + 함수에서 병합 (확장성)

- `core` 에 예: `shift_plan_external(plan_date date, shift_cd text, version_id text, …)` 동기화 테이블을 두고, 외부에서 주기 `COPY`/`INSERT`.
- `fn_shift_cfg_daily` 로직 예시:
  - `내일`이 **토요일**이면  
    `shift_plan_external` 에 `plan_date = 내일` 행이 있으면 → 그 `SHIFT_CD` 로 구간 생성해 `shift_cfg` INSERT.  
    없으면 → **기본 토요일 CASE** (현재 SQL) 사용.
  - `SHIFT_CD` → 구간 매핑은 **`core.shift_cd_pattern(shift_cd, shift_name, start_time, end_time, ord)`** 같은 참조 테이블로 두면 SQL만으로 처리 가능.

---

### 3) 다른 DB의 원본 테이블 직접 조회

- PostgreSQL **FDW**(`postgres_fdw` 등) 또는 **dblink** 로 `OSP_CHK_SAT_*` 가 있는 DB를 조회해, 위와 동일하게 `shift_cfg` 또는 스테이징에 반영.
- 네트워크·권한·스키마 변경에 취약하므로, 가능하면 **주기 ETL로 Edge DB 안으로 끌어오는 2)** 선호.

---

## KPI와의 관계

- KPI는 `shift_map` → `shift_cfg.id` 로 구간을 잡습니다.
- **해당 `work_date`가 토요일**이면, 그날 `shift_cfg` 가 외부 기준과 일치해야 가용시간·OEE가 맞습니다.  
  → **외부 반영 시각**을 그날 첫 교대 시작 **이전**으로 두는 것이 안전합니다.

---

## 정리

| 목표 | 추천 |
|------|------|
| 빠르게 토요일만 외부 반영 | 배치가 `PLAN_DATE`/`SHIFT_CD` 해석 후 `shift_cfg` UPSERT |
| 코드·DB 일원화 | `shift_plan_external` + `shift_cd_pattern` + `fn_shift_cfg_daily` 에서 토요일 분기 |
| 원본이 타 DB 테이블 | ETL 또는 FDW로 Edge로 복제 후 동일 처리 |

`SHIFT_CD` 목록과 구간 매핑이 확정되면 `shift-cfg-daily.sql` 의 토요일 `CASE` 와 한곳에서만 맞추면 됩니다.
