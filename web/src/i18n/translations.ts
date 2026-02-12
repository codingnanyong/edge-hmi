import type { Locale } from '@/contexts/LocaleContext'

export const SERVICE_INFO: Record<
  Locale,
  Record<string, { title: string; description: string }>
> = {
  ko: {
    line_mst: { title: '라인 마스터', description: '라인 마스터 정보 관리 API 서비스' },
    equip_mst: { title: '설비 마스터', description: '설비 마스터 정보 관리 API 서비스' },
    sensor_mst: { title: '센서 마스터', description: '센서 마스터 정보 관리 API 서비스' },
    worker_mst: { title: '작업자 마스터', description: '작업자 마스터 정보 관리 API 서비스' },
    shift_cfg: { title: '근무 교대 설정', description: '근무 교대 설정 관리 API 서비스' },
    kpi_cfg: { title: 'KPI 설정', description: 'KPI 설정 관리 API 서비스' },
    alarm_cfg: { title: '알람 설정', description: '알람 설정 관리 API 서비스' },
    maint_cfg: { title: '보전 설정', description: '보전 설정 관리 API 서비스' },
    work_order: { title: '작업 지시', description: '작업 지시 정보 관리 API 서비스' },
    parts_mst: { title: '부품 마스터', description: '부품 마스터 정보 관리 API 서비스' },
    defect_code_mst: { title: '불량 코드', description: '불량 코드 마스터 API 서비스' },
    measurement: { title: '측정 데이터', description: '측정 데이터 수집 및 조회 API 서비스' },
    equip_status: { title: '설비 상태 이력', description: '설비 상태 구간 이력 조회 API 서비스' },
    sensor_status: { title: '센서 상태', description: '센서 연결/헬스 상태 조회 API 서비스' },
    prod_his: { title: '생산 이력', description: '생산 이력 조회 API 서비스' },
    defect_his: { title: '불량 이력', description: '불량 이력 조회 API 서비스' },
    alarm_his: { title: '알람 이력', description: '알람 이력 조회 API 서비스' },
    maint_his: { title: '보전 이력', description: '보전 이력 조회 API 서비스' },
    shift_map: { title: '근무 교대 매핑', description: '근무 교대 매핑 조회 API 서비스' },
    kpi_sum: { title: 'KPI 집계', description: 'KPI 집계 데이터 조회 API 서비스' },
  },
  en: {
    line_mst: { title: 'Line Master', description: 'Line master information management API' },
    equip_mst: { title: 'Equipment Master', description: 'Equipment master information management API' },
    sensor_mst: { title: 'Sensor Master', description: 'Sensor master information management API' },
    worker_mst: { title: 'Worker Master', description: 'Worker master information management API' },
    shift_cfg: { title: 'Shift Config', description: 'Shift configuration management API' },
    kpi_cfg: { title: 'KPI Config', description: 'KPI configuration management API' },
    alarm_cfg: { title: 'Alarm Config', description: 'Alarm configuration management API' },
    maint_cfg: { title: 'Maintenance Config', description: 'Maintenance configuration management API' },
    work_order: { title: 'Work Order', description: 'Work order information management API' },
    parts_mst: { title: 'Parts Master', description: 'Parts master information management API' },
    defect_code_mst: { title: 'Defect Code', description: 'Defect code master API' },
    measurement: { title: 'Measurement', description: 'Measurement data collection and query API' },
    equip_status: { title: 'Status History', description: 'Equipment status interval history query API' },
    sensor_status: { title: 'Sensor Status', description: 'Sensor connection and health status query API' },
    prod_his: { title: 'Production History', description: 'Production history query API' },
    defect_his: { title: 'Defect History', description: 'Defect history query API' },
    alarm_his: { title: 'Alarm History', description: 'Alarm history query API' },
    maint_his: { title: 'Maintenance History', description: 'Maintenance history query API' },
    shift_map: { title: 'Shift Map', description: 'Shift mapping query API' },
    kpi_sum: { title: 'KPI Summary', description: 'KPI summary data query API' },
  },
}

export const GROUP_TITLES: Record<Locale, Record<string, string>> = {
  ko: {
    '01': 'Overview',
    '02': 'Process & Trend',
    '03': 'Maintenance & Health',
    '04': 'Production Log',
    '99': 'Common Parameters',
  },
  en: {
    '01': 'Overview',
    '02': 'Process & Trend',
    '03': 'Maintenance & Health',
    '04': 'Production Log',
    '99': 'Common Parameters',
  },
}

export const CATEGORY_LABELS: Record<Locale, Record<string, string>> = {
  ko: { 'OS': 'OS', '공통': '공통', 'IP': 'IP', 'OS/MID': 'OS/MID' },
  en: { 'OS': 'OS', '공통': 'Common', 'IP': 'IP', 'OS/MID': 'OS/MID' },
}
