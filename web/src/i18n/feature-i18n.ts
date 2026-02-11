import type { Locale } from '@/contexts/LocaleContext'

type FeatureOverride = { title?: string; purpose?: string; logic?: string; note?: string; formula?: string }

/** Korean overrides for features (locale === 'ko') */
export const FEATURE_KO: Record<string, FeatureOverride> = {
  '1.1': {
    title: '모델별 불량률',
    purpose: '생산 모델별 불량률을 막대 차트로 표시',
    logic: '불량률(%) = Σ(defect_cnt) / Σ(total_cnt) × 100',
    formula: '불량률(%) = Σ(defect_cnt) / Σ(total_cnt) × 100',
  },
  '1.2': {
    title: '작업자별 불량률',
    purpose: '작업자별 불량 수량 막대 차트',
    logic: 'shift_map(work_date, worker_id, equip_id) → prod_his(equip_id, time) → 작업자별 defect_cnt 집계',
    formula: '불량률(%) = Σ(defect_cnt) / Σ(total_cnt) × 100 (작업자별)',
  },
  '1.4': {
    title: '설비 가동 상태',
    purpose: '실시간: 가동(녹색), 정지(빨강), 대기(주황), 알람(깜빡임), 고장(회색)',
    logic: 'equip_status 최신 status_code 사용, alarm_his에 진행 중 알람 있으면 Blink 처리',
    note: 'status_code: Run, Stop, Fault. alarm_his 병합하여 알람 상태 표시',
  },
  '1.5': {
    title: '작업 지시',
    purpose: '지시번호, 품목명/코드, 목표수량, 납기일, SOP',
    logic: 'work_order 테이블의 target_cnt, sop_link 등 주요 필드 직접 매핑',
  },
  '1.6': {
    title: '핵심 KPI',
    purpose: 'OEE, 양품률, 생산진도, 사이클 타임',
    logic: 'kpi_sum 집계 결과와 kpi_cfg 목표값 비교하여 달성률 산출',
    formula: '달성률(%) = actual / target × 100',
  },
  '1.7': {
    title: '단기 추세',
    purpose: '기간/작업자/부품/센서별 다중 시계열 차트 (줌/팬)',
    logic: '선택 조건을 쿼리 필터로 적용하여 고해상도 시계열 시각화',
  },
  '1.8': {
    title: '설비 프로필',
    purpose: '기본 정보 (스펙, CMMS ID, 설치일)',
    logic: 'equip_mst 테이블의 equip_code, name, install_date 등 마스터 데이터 로드',
  },
  '1.9': {
    title: '설비 알람 상태',
    purpose: '설비별 알람 (상태, 센서, 공정 조건)',
    logic: 'alarm_his와 alarm_cfg 조인하여 위험도 및 상세 내용 매핑',
  },
  '2.1': {
    title: '표준 작업 준수',
    purpose: '모터 전류 부하 패턴',
    logic: 'measurement 전류값을 표준 패턴과 비교하여 임계치 이탈 여부 감시',
  },
  '2.2': {
    title: '상태 전이 추세',
    purpose: '가동→대기→정지→고장 타임라인',
    logic: '특정 기간 equip_status를 시간순 나열하여 간트 차트 형태로 구성',
  },
  '2.3': {
    title: '다중 설비 비교',
    purpose: '설비 간 KPI/알람 비교',
    logic: '여러 equip_id의 kpi_sum 데이터를 병렬 배치하여 편차 분석',
  },
  '2.4': {
    title: '다중 시계열 추세',
    purpose: '기간/작업자/부품/센서 차트 (줌/팬)',
    logic: '선택 조건을 쿼리 필터로 적용하여 고해상도 시계열 시각화',
  },
  '2.5': {
    title: '4M1E 분석',
    purpose: '인·기·재·품 상관 분석',
    logic: '작업자 교체(shift_map) 또는 부품 교체(parts_mst) 시점 전후 불량률 변화 추적',
  },
  '2.6': {
    title: '골든 배치 비교',
    purpose: '표준 패턴 대비 실시간 데이터 비교',
    logic: 'is_golden_standard=true 센서 데이터를 배경 레이어로, 실시간 measurement 중첩',
  },
  '2.7': {
    title: '핵심 공정 데이터 분석',
    purpose: '핫플레이트 온도, 몰드 진공, 호퍼 드라이 공정 시각화',
    logic: '특정 공정 센서 그룹화하여 공정 단계별 정상 범위 이탈 여부 확인',
  },
  '3.3': {
    title: '부품 수명 주기',
    purpose: '사용률 %, 교체 알림',
    logic: '사용률(%) = current_usage_hours / spec_lifespan_hours × 100',
    formula: '사용률(%) = current_usage_hours / spec_lifespan_hours × 100',
  },
  '3.4': {
    title: '고장/보수 타임라인',
    purpose: '고장 발생 → 조치 완료',
    logic: 'alarm_his.time과 maint_his.end_time 차이로 조치 소요 시간 산출',
  },
  '3.5': {
    title: '다운타임 분석',
    purpose: '파레토, MTBF, MTTR',
    logic: 'alarm_his를 사유별 그룹화하여 빈도 계산, kpi_sum의 MTBF/MTTR 표시',
  },
  '3.6': {
    title: 'PM 알림',
    purpose: '정비 주기 도래 시 점검 알림',
    logic: '부품 사용률 90% 초과 또는 정비 예정일 도래 시 알림 트리거',
  },
  '3.7': {
    title: '센서 상태',
    purpose: '데이터 유효성 및 통신 상태',
    logic: 'measurement 수집 주기 확인, 미수신 시 "통신 이상" 판단',
  },
  '3.8': {
    title: '히팅선 단선',
    purpose: 'Station별 히팅선 단선 개수 표시',
    logic: '히팅선 전류 센서 알람과 Station 위치 정보 결합하여 레이아웃 표기',
  },
  '4.1': {
    title: '생산 성과',
    purpose: 'UPH, Lot 양품률, 사이클 타임',
    logic: '일자별 prod_his 합산하여 시간 단위 생산 흐름 분석',
  },
  '4.2': {
    title: '불량 원인 분석',
    purpose: '불량 유형별 파레토',
    logic: '불량 유형별 발생 횟수 내림차순 정렬, 누적 백분율과 함께 그래프화',
  },
  '4.3': {
    title: '생산 이력 조회',
    purpose: '품번 클릭 → 생산 시점 센서 조건',
    logic: '제품 생산 시점(time) 기준으로 measurement 범위 매칭하여 조회',
  },
  '4.4': {
    title: '품질 통계',
    purpose: '검사값 평균, 표준편차 (LCL/UCL)',
    logic: '품질 센서 데이터 분류하여 관리 한계선(LCL/UCL) 이탈 여부 판단',
  },
  params: {
    title: '조회 파라미터',
    purpose: '전체 API 공통 지원',
    logic: 'skip, limit, work_date, time_from, time_to 등',
  },
}

/** English overrides for features (locale === 'en') */
export const FEATURE_EN: Record<string, FeatureOverride> = {
  '1.4': {
    logic: 'Use latest status_code from equip_status; apply Blink if ongoing alarm in alarm_his',
    note: 'status_code: Run, Stop, Fault. Merge alarm_his for alarm status.',
  },
  '1.5': { logic: 'Direct mapping of target_cnt, sop_link etc. from work_order table' },
  '1.6': { logic: 'Compare kpi_sum results with kpi_cfg targets to calculate achievement rate' },
  '1.7': {
    title: 'Short-term Trend',
    purpose: 'Multi-time-series chart by period, worker, part, sensor (zoom/pan)',
    logic: 'Apply selected parameters as query filters for high-res time-series visualization',
  },
  '1.8': { logic: 'Load master data (equip_code, name, install_date) from equip_mst' },
  '1.9': { logic: 'Join alarm_his and alarm_cfg to map Severity and details' },
  '2.1': { logic: 'Compare measurement current with standard pattern for threshold deviation' },
  '2.2': { logic: 'Arrange equip_status chronologically as Gantt chart' },
  '2.3': { logic: 'Arrange kpi_sum for multiple equip_ids in parallel for deviation analysis' },
  '2.4': { logic: 'Apply selected parameters as query filters for high-res time-series viz' },
  '2.5': {
    logic: 'Track defect rate change before/after worker (shift_map) or parts (parts_mst) change',
  },
  '2.6': {
    logic: 'Overlay real-time measurement on sensor data with is_golden_standard=true',
  },
  '2.7': {
    logic: 'Group process sensors to check deviation from normal range per process step',
  },
  '3.4': { logic: 'Calculate duration from alarm_his.time to maint_his.end_time' },
  '3.5': { logic: 'Group alarm_his by reason for frequency; show MTBF/MTTR from kpi_sum' },
  '3.6': { logic: 'Trigger alert when parts usage >90% or scheduled maintenance date reached' },
  '3.7': { logic: 'Check measurement collection cycle; judge "comm abnormal" if no data' },
  '3.8': {
    title: 'Heating Wire Disconnection',
    purpose: 'Display disconnection count per Station on layout',
    logic: 'Combine heating wire current sensor alarm with Station position on layout',
  },
  '4.1': { logic: 'Sum daily prod_his for hourly production flow analysis' },
  '4.2': { logic: 'Sort defect types by count desc, graph with cumulative percentage' },
  '4.3': { logic: 'Match measurement range by product production time' },
  '4.4': {
    title: 'Quality Statistics',
    purpose: 'Average, std dev of inspection values (LCL/UCL)',
    logic: 'Classify quality sensor data to judge LCL/UCL deviation',
  },
  params: { logic: 'skip, limit, work_date, time_from, time_to etc.' },
}

export function getFeatureForLocale<T extends { id: string; title: string; purpose: string; logic: string; note?: string }>(
  feature: T,
  locale: Locale
): T {
  const overrides = locale === 'ko' ? FEATURE_KO[feature.id] : FEATURE_EN[feature.id]
  if (!overrides) return feature
  return {
    ...feature,
    title: overrides.title ?? feature.title,
    purpose: overrides.purpose ?? feature.purpose,
    logic: overrides.logic ?? feature.logic,
    note: overrides.note ?? feature.note,
    ...(overrides.formula !== undefined && { formula: overrides.formula }),
  } as T
}
