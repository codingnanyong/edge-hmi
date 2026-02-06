/**
 * Edge HMI API - Feature usage data (how to use each feature)
 */
const FEATURE_USAGE = {
  baseUrl: "/",
  groups: [
    {
      id: "01",
      title: "Overview",
      features: [
        {
          id: "1.1",
          title: "Defect Rate by Model",
          purpose: "Display defect rate per production model as a bar chart",
          steps: [
            { api: "work_order", curl: 'curl "{{BASE}}/work_order"' },
            { api: "prod_his (by work_order_id)", curl: 'curl "{{BASE}}/prod_his?work_order_id=1&limit=500"' },
            { api: "defect_code_mst", curl: 'curl "{{BASE}}/defect_code_mst"' },
          ],
          formula: "Defect rate(%) = Σ(defect_cnt) / Σ(total_cnt) × 100",
          code: "workOrders.map(wo => { const prodList = prodHisByWo[wo.id] || []; const total = prodList.reduce((s,p) => s + p.total_cnt, 0); const defect = prodList.reduce((s,p) => s + p.defect_cnt, 0); return { model: wo.model_name, defectRate: total ? (defect/total*100).toFixed(2) : 0 }; });",
        },
        {
          id: "1.2",
          title: "Defect Rate by Worker",
          purpose: "Bar chart of defect quantity per worker",
          steps: [
            { api: "shift_map", curl: 'curl "{{BASE}}/shift_map?work_date=2025-01-01&limit=500"' },
            { api: "worker_mst", curl: 'curl "{{BASE}}/worker_mst"' },
            { api: "prod_his", curl: 'curl "{{BASE}}/prod_his?equip_id=1&limit=500"' },
            { api: "defect_his", curl: 'curl "{{BASE}}/defect_his?prod_his_id=1"' },
          ],
          logic: "shift_map(work_date,worker_id,equip_id) → prod_his(equip_id,time) → aggregate defect_cnt per worker",
        },
        {
          id: "1.4",
          title: "Equipment Operating Status",
          purpose: "Real-time: Operating(Green), Stopped(Red), Idle(Orange), Alarm(Blink), Fault(Grey)",
          steps: [
            { api: "status_his", curl: 'curl "{{BASE}}/status_his?equip_id=1&start_time_from=...&start_time_to=...&limit=200"' },
          ],
          note: "status_code: Run, Stop, Fault. Merge alarm_his for alarm status.",
        },
        {
          id: "1.5",
          title: "Work Order",
          purpose: "Order number, item name/code, target quantity, due date, SOP",
          steps: [{ api: "work_order", curl: 'curl "{{BASE}}/work_order"' }],
        },
        {
          id: "1.6",
          title: "Key KPIs",
          purpose: "OEE, good product rate, production progress vs target, cycle time",
          steps: [
            { api: "kpi_sum", curl: 'curl "{{BASE}}/kpi_sum?calc_date=2025-01-01&equip_id=1"' },
            { api: "kpi_cfg", curl: 'curl "{{BASE}}/kpi_cfg"' },
          ],
        },
        {
          id: "1.8",
          title: "Equipment Profile",
          purpose: "Basic info (specs, CMMS ID, install_date)",
          steps: [{ api: "equip_mst", curl: 'curl "{{BASE}}/equip_mst/1"' }],
        },
        {
          id: "1.9",
          title: "Equipment Alarm Status",
          purpose: "Alarms per equipment (status, sensor, process conditions)",
          steps: [
            { api: "alarm_his", curl: 'curl "{{BASE}}/alarm_his?equip_id=1&limit=50"' },
            { api: "alarm_cfg", curl: 'curl "{{BASE}}/alarm_cfg"' },
          ],
        },
      ],
    },
    {
      id: "02",
      title: "Process & Trend",
      features: [
        { id: "2.1", title: "Standard Work Compliance", purpose: "Motor current load patterns", steps: [{ api: "sensor_mst, measurement", curl: "Filter by sensor_id, time_from, time_to" }] },
        { id: "2.2", title: "Status Transition Trend", purpose: "Operating→Idle→Stopped→Fault", steps: [{ api: "status_his", curl: 'curl "{{BASE}}/status_his?equip_id=1&start_time_from=...&start_time_to=..."' }] },
        { id: "2.3", title: "Multi-equipment Comparison", purpose: "Compare KPI/alarm across equipment", steps: [{ api: "kpi_sum, alarm_his", curl: "Query per equip_id" }] },
        { id: "2.4", title: "Multi-time-series Trend", purpose: "Period/worker/part/sensor charts", steps: [{ api: "measurement", curl: 'curl "{{BASE}}/measurement?equip_id=1&sensor_id=2&time_from=...&time_to=...&limit=1000"' }] },
      ],
    },
    {
      id: "03",
      title: "Maintenance & Health",
      features: [
        { id: "3.3", title: "Parts Life Cycle", purpose: "Usage %, replacement notice", steps: [{ api: "parts_mst", curl: 'curl "{{BASE}}/parts_mst?equip_id=1"' }], formula: "Usage(%) = current_usage_hours / spec_lifespan_hours * 100" },
        { id: "3.4", title: "Fault/Repair Timeline", purpose: "Fault occurrence → action completion", steps: [{ api: "maint_his, alarm_his", curl: "Query by equip_id" }] },
        { id: "3.5", title: "Downtime Analysis", purpose: "Pareto, MTBF, MTTR", steps: [{ api: "kpi_sum, alarm_his, alarm_cfg", curl: "" }] },
      ],
    },
    {
      id: "04",
      title: "Production Log",
      features: [
        { id: "4.1", title: "Production Performance", purpose: "UPH, Lot good rate, cycle time", steps: [{ api: "kpi_sum, prod_his, kpi_cfg", curl: "" }] },
        { id: "4.3", title: "Defect Cause Analysis", purpose: "Pareto by defect type", steps: [{ api: "defect_his, defect_code_mst", curl: 'curl "{{BASE}}/defect_his?limit=500"' }] },
      ],
    },
    {
      id: "99",
      title: "Common Parameters",
      features: [
        { id: "params", title: "Query Parameters", purpose: "All APIs support", steps: [
          { api: "skip", curl: "skip=0" },
          { api: "limit", curl: "limit=500" },
          { api: "work_date", curl: "work_date=2025-01-01" },
          { api: "time_from, time_to", curl: "ISO 8601, + → %2B" },
        ]},
      ],
    },
  ],
};
