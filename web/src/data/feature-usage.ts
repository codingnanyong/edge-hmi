export type FeatureCategory = 'OS' | '공통' | 'IP' | 'OS/MID'

export type Feature = {
  id: string
  title: string
  purpose: string
  category: FeatureCategory
  dataSource: string
  logic: string
  steps: Array<{ api: string; curl: string }>
  formula?: string
  note?: string
  code?: string
}

export const FEATURE_USAGE = {
  baseUrl: '/',
  groups: [
    {
      id: '01',
      title: 'Overview',
      features: [
        {
          id: '1.1',
          title: 'Defect Rate by Model',
          purpose: 'Display defect rate per production model as a bar chart',
          category: '공통',
          dataSource: 'work_order, prod_his, defect_code_mst',
          logic: 'Defect rate(%) = Σ(defect_cnt) / Σ(total_cnt) × 100',
          steps: [
            { api: 'work_order', curl: 'curl "{{BASE}}/work_order"' },
            { api: 'prod_his (by work_order_id)', curl: 'curl "{{BASE}}/prod_his?work_order_id=1&limit=500"' },
            { api: 'defect_code_mst', curl: 'curl "{{BASE}}/defect_code_mst"' },
          ],
          formula: 'Defect rate(%) = Σ(defect_cnt) / Σ(total_cnt) × 100',
          code: `workOrders.map(wo => {
  const prodList = prodHisByWo[wo.id] || [];
  const total = prodList.reduce((s, p) => s + p.total_cnt, 0);
  const defect = prodList.reduce((s, p) => s + p.defect_cnt, 0);
  return {
    model: wo.model_name,
    defectRate: total ? (defect / total * 100).toFixed(2) : 0
  };
});`,
        },
        {
          id: '1.2',
          title: 'Defect Rate by Worker',
          purpose: 'Bar chart of defect quantity per worker',
          category: '공통',
          dataSource: 'shift_map, worker_mst, prod_his, defect_his',
          logic: 'shift_map(work_date, worker_mst_id, equip_mst_id) → prod_his(equip_mst_id, time) → aggregate defect_cnt per worker',
          formula: 'Defect rate(%) = Σ(defect_cnt) / Σ(total_cnt) × 100 (per worker)',
          steps: [
            { api: 'shift_map', curl: 'curl "{{BASE}}/shift_map?work_date=2025-01-01&limit=500"' },
            { api: 'worker_mst', curl: 'curl "{{BASE}}/worker_mst"' },
            { api: 'prod_his', curl: 'curl "{{BASE}}/prod_his?equip_mst_id=1&limit=500"' },
            { api: 'defect_his', curl: 'curl "{{BASE}}/defect_his?prod_his_id=1"' },
          ],
          code: `shiftMap
  .filter(s => s.work_date === workDate)
  .map(s => {
    const prodList = prodHisByEquip[s.equip_mst_id] || [];
    const total = prodList.reduce((sum, p) => sum + p.total_cnt, 0);
    const defect = prodList.reduce((sum, p) => sum + p.defect_cnt, 0);
    const worker = workerMst.find(w => w.id === s.worker_mst_id);
    return {
      workerName: worker?.worker_name ?? s.worker_mst_id,
      defectRate: total ? (defect / total * 100).toFixed(2) : 0,
    };
  });`,
        },
        {
          id: '1.4',
          title: 'Equipment Operating Status',
          purpose: 'Real-time: Operating(Green), Stopped(Red), Idle(Orange), Alarm(Blink), Fault(Grey)',
          category: '공통',
          dataSource: 'equip_status, alarm_his',
          logic: 'equip_status 최신 status_code 사용, alarm_his에 진행 중 알람 있으면 Blink 처리',
          note: 'status_code: Run, Stop, Fault. Merge alarm_his for alarm status.',
          steps: [
            { api: 'equip_status', curl: 'curl "{{BASE}}/equip_status?equip_mst_id=1&start_time_from=...&start_time_to=...&limit=200"' },
          ],
          code: `const latest = statusHis
  .filter(s => s.equip_mst_id === equipId)
  .sort((a, b) => new Date(b.start_time) - new Date(a.start_time))[0];
const hasOngoingAlarm = alarmHis.some(a => !a.end_time && a.equip_mst_id === equipId);
const status = latest?.status_code ?? 'Unknown';
const blink = hasOngoingAlarm ? 'Blink' : null;
// Map: Run→Green, Stop→Red, Idle→Orange, Fault→Grey, Alarm→Blink`,
        },
        {
          id: '1.5',
          title: 'Work Order',
          purpose: 'Order number, model name, target quantity, period, SOP',
          category: '공통',
          dataSource: 'work_order',
          logic: 'work_order 테이블의 order_no, model_name, target_cnt, start_date/end_date, sop_link를 그대로 카드에 표시',
          steps: [{ api: 'work_order', curl: 'curl "{{BASE}}/work_order"' }],
          code: `workOrders.map(wo => ({
  orderNo: wo.order_no,
  modelName: wo.model_name,
  targetCnt: wo.target_cnt,
  startDate: wo.start_date,
  endDate: wo.end_date,
  sopLink: wo.sop_link,
}));`,
        },
        {
          id: '1.6',
          title: 'Key KPIs',
          purpose: 'OEE, good product rate, production progress vs target, cycle time',
          category: '공통',
          dataSource: 'kpi_sum, kpi_cfg',
          logic: 'kpi_sum의 availability/performance/quality/oee/MTBF/MTTR/UPH 값을 사용하고, kpi_cfg.target_oee와 비교해 달성률 계산',
          formula: 'OEE Achievement(%) = oee / target_oee × 100',
          steps: [
            { api: 'kpi_sum', curl: 'curl "{{BASE}}/kpi_sum?calc_date=2025-01-01&equip_mst_id=1"' },
            { api: 'kpi_cfg', curl: 'curl "{{BASE}}/kpi_cfg"' },
          ],
          code: `const row = kpiSum[0]; // 단일 설비/일자 기준
const cfg = kpiCfg.find(c => c.equip_mst_id === row.equip_mst_id);
const targetOee = cfg?.target_oee ?? 0;
const oee = row.oee ?? 0;
return {
  availability: row.availability,
  performance: row.performance,
  quality: row.quality,
  oee,
  mtbf: row.mtbf,
  mttr: row.mttr,
  uph: row.uph,
  targetOee,
  oeeAchievement: targetOee ? (oee / targetOee * 100).toFixed(1) : '-',
};`,
        },
        {
          id: '1.7',
          title: 'Short-term Trend',
          purpose: 'Multi-time-series chart by period, worker, part, sensor (zoom/pan)',
          category: '공통',
          dataSource: 'measurement, shift_map',
          logic: '선택 조건(Parameter)을 쿼리 필터로 적용하여 고해상도 시계열 시각화',
          steps: [
            { api: 'measurement', curl: 'curl "{{BASE}}/measurement?equip_mst_id=1&sensor_mst_id=2&time_from=...&time_to=...&limit=1000"' },
            { api: 'shift_map', curl: 'curl "{{BASE}}/shift_map?work_date=2025-01-01"' },
          ],
          code: `// time_from, time_to, equip_mst_id, sensor_mst_id 등 선택 파라미터를 쿼리에 적용
const params = { equip_mst_id, sensor_mst_id, time_from, time_to, limit: 1000 };
const data = await fetch(\`\${base}/measurement?\${new URLSearchParams(params)}\`);
const points = data.map(d => ({ time: d.timestamp, value: d.value }));
// 시계열 차트 라이브러리로 points 렌더링 (줌/팬 지원)`,
        },
        {
          id: '1.8',
          title: 'Equipment Profile',
          purpose: 'Basic info (specs, CMMS ID, install_date)',
          category: '공통',
          dataSource: 'equip_mst',
          logic: 'equip_mst 테이블의 equip_code, equip_name, install_date 등 마스터 데이터 로드',
          steps: [{ api: 'equip_mst', curl: 'curl "{{BASE}}/equip_mst/1"' }],
          code: `const equip = await fetch(\`\${base}/equip_mst/\${equipId}\`);
return {
  code: equip.equip_code,
  name: equip.equip_name,
  installDate: equip.install_date,
  cmmsId: equip.cmms_id,
};`,
        },
        {
          id: '1.9',
          title: 'Equipment Alarm Status',
          purpose: 'Alarms per equipment (status, sensor, process conditions)',
          category: '공통',
          dataSource: 'alarm_his, alarm_cfg',
          logic: 'alarm_his와 alarm_cfg 조인하여 위험도(Severity) 및 상세 내용 매핑',
          steps: [
            { api: 'alarm_his', curl: 'curl "{{BASE}}/alarm_his?equip_mst_id=1&limit=50"' },
            { api: 'alarm_cfg', curl: 'curl "{{BASE}}/alarm_cfg"' },
          ],
          code: `alarmHis
  .filter(a => a.equip_mst_id === equipId)
  .map(a => {
    const cfg = alarmCfg.find(c => c.id === a.alarm_cfg_id);
    return {
      ...a,
      severity: cfg?.severity,
      description: cfg?.description ?? a.message,
    };
  });`,
        },
      ],
    },
    {
      id: '02',
      title: 'Process & Trend',
      features: [
        {
          id: '2.1',
          title: 'Standard Work Compliance',
          purpose: 'Motor current load patterns',
          category: 'OS/MID',
          dataSource: 'sensor_mst, measurement',
          logic: 'measurement 전류값을 표준 패턴과 비교하여 임계치 이탈 여부 감시',
          steps: [
            { api: 'sensor_mst', curl: 'curl "{{BASE}}/sensor_mst?equip_mst_id=1"' },
            { api: 'measurement', curl: 'curl "{{BASE}}/measurement?equip_mst_id=1&sensor_mst_id=3&time_from=...&time_to=..."' },
          ],
          code: `const current = measurement.map(m => m.value);
const standardPattern = [/* reference curve */];
const deviation = current.map((v, i) =>
  Math.abs(v - (standardPattern[i] ?? v))
);
const outOfRange = deviation.some(d => d > threshold);`,
        },
        {
          id: '2.2',
          title: 'Status Transition Trend',
          purpose: 'Operating→Idle→Stopped→Fault timeline',
          category: 'OS/MID',
          dataSource: 'equip_status',
          logic: '특정 기간 equip_status를 시간순 나열하여 간트 차트 형태로 구성',
          steps: [{ api: 'equip_status', curl: 'curl "{{BASE}}/equip_status?equip_mst_id=1&start_time_from=...&start_time_to=..."' }],
          code: `const sorted = statusHis
  .filter(s => s.equip_mst_id === equipId)
  .sort((a, b) => new Date(a.start_time) - new Date(b.start_time));
// Gantt: each row = status block, x = time, color by status_code`,
        },
        {
          id: '2.3',
          title: 'Multi-equipment Comparison',
          purpose: 'Compare KPI/alarm across equipment',
          category: 'OS/MID',
          dataSource: 'kpi_sum, alarm_his',
          logic: '여러 equip_mst_id의 kpi_sum 데이터를 병렬 배치하여 편차 분석',
          steps: [
            { api: 'kpi_sum', curl: 'curl "{{BASE}}/kpi_sum?calc_date=2025-01-01"' },
            { api: 'alarm_his', curl: 'curl "{{BASE}}/alarm_his?equip_mst_id=1"' },
          ],
          code: `const byEquip = Object.groupBy(kpiSum, k => k.equip_mst_id);
equipIds.forEach(eid => {
  const vals = (byEquip[eid] || []).map(k => k.oee ?? 0);
  const mean = avg(vals), std = stdDev(vals);
  // Bar chart: equip vs OEE, highlight outlier if |v - mean| > 2*std
});`,
        },
        {
          id: '2.4',
          title: 'Multi-time-series Trend',
          purpose: 'Period/worker/part/sensor charts (zoom/pan)',
          category: '공통',
          dataSource: 'measurement, shift_map',
          logic: '선택 조건(Parameter)을 쿼리 필터로 적용하여 고해상도 시계열 시각화',
          steps: [{ api: 'measurement', curl: 'curl "{{BASE}}/measurement?equip_mst_id=1&sensor_mst_id=2&time_from=...&time_to=...&limit=1000"' }],
          code: `// Same as 1.7: filter by equip_mst_id, sensor_mst_id, time_from, time_to
const series = measurement
  .filter(m => applyFilters(m, filters))
  .map(m => ({ x: m.time, y: m.value }));`,
        },
        {
          id: '2.5',
          title: '4M1E Analysis',
          purpose: 'Correlation analysis: human, machine, material, quality',
          category: '공통',
          dataSource: 'shift_map, parts_mst, prod_his, defect_his',
          logic: '작업자 교체(shift_map) 또는 부품 교체(parts_mst) 시점 전후 불량률 변화 추적',
          steps: [
            { api: 'shift_map', curl: 'curl "{{BASE}}/shift_map?work_date=2025-01-01"' },
            { api: 'parts_mst', curl: 'curl "{{BASE}}/parts_mst?equip_mst_id=1"' },
            { api: 'prod_his', curl: 'curl "{{BASE}}/prod_his?equip_mst_id=1"' },
            { api: 'defect_his', curl: 'curl "{{BASE}}/defect_his?limit=500"' },
          ],
          code: `const changePoints = [...workerChanges, ...partsChanges].sort(byTime);
changePoints.forEach(({ time, type }) => {
  const before = defectRateBefore(time);
  const after = defectRateAfter(time);
  // Compare before vs after, show delta %
});`,
        },
        {
          id: '2.6',
          title: 'Golden Batch Comparison',
          purpose: 'Real-time comparison of standard pattern vs current data',
          category: '공통',
          dataSource: 'sensor_mst, measurement',
          logic: 'is_golden_standard=true 센서 데이터를 배경 레이어로, 실시간 measurement 중첩',
          steps: [
            { api: 'sensor_mst', curl: 'curl "{{BASE}}/sensor_mst?equip_mst_id=1"' },
            { api: 'measurement', curl: 'curl "{{BASE}}/measurement?equip_mst_id=1&sensor_mst_id=1"' },
          ],
          code: `const goldenSensors = sensorMst.filter(s => s.is_golden_standard);
const goldenIds = new Set(goldenSensors.map(s => s.id));
const golden = measurement.filter(m => goldenIds.has(m.sensor_mst_id));
const current = measurement.filter(m => !goldenIds.has(m.sensor_mst_id));
// Chart: layer 1 = golden (dim), layer 2 = current (highlight)`,
        },
        {
          id: '2.7',
          title: 'Key Process Data Analysis',
          purpose: 'Hot plate temp, mold vacuum, Hopper Dry process visualization',
          category: 'IP',
          dataSource: 'sensor_mst, measurement',
          logic: 'sensor_mst에서 공정별 주요 센서 그룹을 정의하고, measurement 값을 센서 그룹 단위로 집계하여 정상 범위 이탈 여부 확인',
          steps: [
            { api: 'sensor_mst', curl: 'curl "{{BASE}}/sensor_mst?equip_mst_id=1"' },
            { api: 'measurement', curl: 'curl "{{BASE}}/measurement?equip_mst_id=1&sensor_mst_id=2"' },
          ],
          code: `const withMeta = measurement.map(m => ({
  ...m,
  sensor: sensorMst.find(s => s.id === m.sensor_mst_id),
}));
const bySensorCode = groupBy(withMeta, m => m.sensor?.sensor_name);
Object.entries(bySensorCode).forEach(([code, vals]) => {
  const inRange = vals.filter(v => v.value >= minRange && v.value <= maxRange);
  const outOfRange = vals.length - inRange.length;
});`,
        },
      ],
    },
    {
      id: '03',
      title: 'Maintenance & Health',
      features: [
        {
          id: '3.3',
          title: 'Parts Life Cycle',
          purpose: 'Usage %, replacement notice',
          category: '공통',
          dataSource: 'parts_mst',
          logic: 'Usage(%) = current_usage_hours / spec_lifespan_hours × 100',
          formula: 'Usage(%) = current_usage_hours / spec_lifespan_hours × 100',
          steps: [{ api: 'parts_mst', curl: 'curl "{{BASE}}/parts_mst?equip_mst_id=1"' }],
          code: `partsMst.map(p => ({
  partName: p.part_name,
  usagePct: (p.current_usage_hours / p.spec_lifespan_hours * 100).toFixed(1),
  needReplace: p.current_usage_hours / p.spec_lifespan_hours > 0.9,
}));`,
        },
        {
          id: '3.4',
          title: 'Fault/Repair Timeline',
          purpose: 'Fault occurrence → action completion',
          category: '공통',
          dataSource: 'maint_his, alarm_his',
          logic: 'alarm_his.time과 maint_his.end_time 차이로 조치 소요 시간 산출',
          steps: [
            { api: 'maint_his', curl: 'curl "{{BASE}}/maint_his?equip_mst_id=1"' },
            { api: 'alarm_his', curl: 'curl "{{BASE}}/alarm_his?equip_mst_id=1"' },
          ],
          code: `alarmHis.map(a => {
  const maint = maintHis.find(m => m.alarm_his_id === a.id);
  const duration = maint?.end_time
    ? (new Date(maint.end_time) - new Date(a.time)) / 60000
    : null;
  return { faultTime: a.time, durationMin: duration };
});`,
        },
        {
          id: '3.5',
          title: 'Downtime Analysis',
          purpose: 'Pareto, MTBF, MTTR',
          category: '공통',
          dataSource: 'kpi_sum, alarm_his, alarm_cfg',
          logic: 'alarm_his를 사유별 그룹화하여 빈도 계산, kpi_sum의 MTBF/MTTR 표시',
          steps: [
            { api: 'kpi_sum', curl: 'curl "{{BASE}}/kpi_sum?calc_date=2025-01-01"' },
            { api: 'alarm_his', curl: 'curl "{{BASE}}/alarm_his?equip_mst_id=1"' },
            { api: 'alarm_cfg', curl: 'curl "{{BASE}}/alarm_cfg"' },
          ],
          code: `const byReason = Object.groupBy(alarmHis, a => {
  const cfg = alarmCfg.find(c => c.id === a.alarm_cfg_id);
  return cfg?.alarm_code ?? 'UNKNOWN';
});
const pareto = Object.entries(byReason)
  .map(([r, list]) => ({ reason: r, count: list.length }))
  .sort((a, b) => b.count - a.count);
const row = kpiSum[0];
const mtbf = row?.mtbf;
const mttr = row?.mttr;`,
        },
        {
          id: '3.6',
          title: 'PM Notification',
          purpose: 'Inspection alert when maintenance cycle reached',
          category: '공통',
          dataSource: 'parts_mst, alarm_cfg',
          logic: '부품 사용률 90% 초과 또는 정비 예정일 도래 시 알림 트리거',
          steps: [
            { api: 'parts_mst', curl: 'curl "{{BASE}}/parts_mst?equip_mst_id=1"' },
            { api: 'alarm_cfg', curl: 'curl "{{BASE}}/alarm_cfg"' },
          ],
          code: `partsMst.filter(p => {
  const usagePct = p.current_usage_hours / p.spec_lifespan_hours * 100;
  const dateDue = p.scheduled_maintenance_date && new Date(p.scheduled_maintenance_date) <= today;
  return usagePct > 90 || dateDue;
});`,
        },
        {
          id: '3.7',
          title: 'Sensor Status',
          purpose: 'Sensor power/connection and data collection health; normality of sensor values and conn_status',
          category: '공통',
          dataSource: 'sensor_mst, sensor_status, alarm_his',
          logic: 'sensor_status.last_seen 갱신 주기를 sensor_mst.sampling_rate 기준으로 확인하여 통신/수집 이상 판단',
          steps: [
            { api: 'sensor_mst', curl: 'curl "{{BASE}}/sensor_mst?equip_mst_id=1"' },
            { api: 'sensor_status', curl: 'curl "{{BASE}}/sensor_status?sensor_mst_id=1" or "{{BASE}}/sensor_status/by-sensor/1"' },
            { api: 'alarm_his', curl: 'curl "{{BASE}}/alarm_his?equip_mst_id=1"' },
          ],
          code: `sensorMst.map(s => {
  const status = sensorStatus.find(ss => ss.sensor_mst_id === s.id);
  const expectedIntervalSec = s.sampling_rate ? 1 / s.sampling_rate : 60;
  const lastSeen = status?.last_seen ? new Date(status.last_seen).getTime() : 0;
  const gapSec = lastSeen ? (Date.now() - lastSeen) / 1000 : Infinity;
  const connOk = gapSec <= expectedIntervalSec * 2;
  return {
    sensorId: s.id,
    conn_status: status?.conn_status ?? (connOk ? 'connected' : 'disconnected'),
    health_score: status?.health_score,
    error_msg: status?.error_msg,
    last_seen: status?.last_seen,
  };
});`,
        },
        {
          id: '3.8',
          title: 'Heating Wire Disconnection',
          purpose: 'Station별 히팅선 단선 개수 표시',
          category: 'OS',
          dataSource: 'alarm_his, sensor_mst',
          logic: '히팅선 전류 센서 알람과 Station 위치 정보 결합하여 레이아웃 표기',
          steps: [
            { api: 'alarm_his', curl: 'curl "{{BASE}}/alarm_his?equip_mst_id=1"' },
            { api: 'sensor_mst', curl: 'curl "{{BASE}}/sensor_mst?equip_mst_id=1"' },
          ],
          code: `const heatingSensors = sensorMst.filter(s => s.sensor_type === 'heating_wire');
const byStation = Object.groupBy(
  alarmHis.filter(a => heatingSensors.some(h => h.id === a.sensor_mst_id)),
  a => sensorMst.find(s => s.id === a.sensor_mst_id)?.station_id
);
// Layout: station position + count per station`,
        },
      ],
    },
    {
      id: '04',
      title: 'Production Log',
      features: [
        {
          id: '4.1',
          title: 'Production Performance',
          purpose: 'UPH, Lot good rate, cycle time',
          category: 'IP',
          dataSource: 'kpi_sum, prod_his, kpi_cfg',
          logic: '일자별 prod_his 합산하여 시간 단위 생산 흐름 분석',
          steps: [
            { api: 'kpi_sum', curl: 'curl "{{BASE}}/kpi_sum?calc_date=2025-01-01"' },
            { api: 'prod_his', curl: 'curl "{{BASE}}/prod_his?work_order_id=1"' },
            { api: 'kpi_cfg', curl: 'curl "{{BASE}}/kpi_cfg"' },
          ],
          code: `const uph = kpiSum.find(k => k.kpi_code === 'UPH')?.value;
const goodRate = kpiSum.find(k => k.kpi_code === 'good_rate')?.value;
const hourly = prodHis.reduce((acc, p) => {
  const h = new Date(p.time).getHours();
  acc[h] = (acc[h] || 0) + p.total_cnt;
  return acc;
}, {});`,
        },
        {
          id: '4.2',
          title: 'Defect Cause Analysis',
          purpose: 'Pareto by defect type',
          category: '공통',
          dataSource: 'defect_his, defect_code_mst',
          logic: '불량 유형별 발생 횟수 내림차순 정렬, 누적 백분율과 함께 그래프화',
          formula: 'Cumulative % = Σ(count up to i) / Σ(total) × 100',
          steps: [{ api: 'defect_his, defect_code_mst', curl: 'curl "{{BASE}}/defect_his?limit=500"' }],
          code: `const byType = Object.groupBy(defectHis, d => d.defect_code_mst_id);
const pareto = Object.entries(byType)
  .map(([code, list]) => ({ code, count: list.length, name: defectCodeMst[code]?.reason_name }))
  .sort((a, b) => b.count - a.count);
const total = pareto.reduce((s, p) => s + p.count, 0);
pareto.forEach((p, i) => {
  p.cumPct = pareto.slice(0, i + 1).reduce((s, x) => s + x.count, 0) / total * 100;
});`,
        },
        {
          id: '4.3',
          title: 'Production History Inquiry',
          purpose: 'Product number click → sensor conditions at production time',
          category: '공통',
          dataSource: 'prod_his, measurement',
          logic: '제품 생산 시점(time) 기준으로 measurement 범위 매칭하여 조회',
          steps: [
            { api: 'prod_his', curl: 'curl "{{BASE}}/prod_his?work_order_id=1"' },
            { api: 'measurement', curl: 'curl "{{BASE}}/measurement?equip_mst_id=1"' },
          ],
          code: `const prod = prodHis.find(p => p.id === prodHisId);
const window = 60; // seconds
const range = measurement.filter(m =>
  m.equip_mst_id === prod.equip_mst_id &&
  Math.abs(new Date(m.time) - new Date(prod.time)) / 1000 <= window
);`,
        },
        {
          id: '4.4',
          title: 'Quality Statistics',
          purpose: 'Average, standard deviation of inspection values (LCL/UCL)',
          category: '공통',
          dataSource: 'measurement',
          logic: '품질 센서 데이터 분류하여 관리 한계선(LCL/UCL) 이탈 여부 판단',
          formula: 'UCL = μ + 3σ, LCL = μ - 3σ',
          steps: [{ api: 'measurement', curl: 'curl "{{BASE}}/measurement?equip_mst_id=1&sensor_mst_id=2"' }],
          code: `const vals = measurement.map(m => m.value);
const mean = vals.reduce((a, b) => a + b, 0) / vals.length;
const std = Math.sqrt(vals.reduce((s, v) => s + (v - mean) ** 2, 0) / vals.length);
const ucl = mean + 3 * std, lcl = mean - 3 * std;
const outOfControl = vals.filter(v => v > ucl || v < lcl);`,
        },
      ],
    },
    {
      id: '99',
      title: 'Common Parameters',
      features: [
        {
          id: 'params',
          title: 'Query Parameters',
          purpose: 'All APIs support',
          category: '공통',
          dataSource: '-',
          logic: 'skip, limit, work_date, time_from, time_to 등',
          steps: [
            { api: 'skip', curl: 'skip=0' },
            { api: 'limit', curl: 'limit=500' },
            { api: 'work_date', curl: 'work_date=2025-01-01' },
            { api: 'time_from, time_to', curl: 'ISO 8601, + → %2B' },
          ],
        },
      ],
    },
  ],
}
