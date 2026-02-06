# Edge HMI Feature API Usage Guide

Base URL: `http://{publish ip}` (or `http://localhost:8000`)

---

## 01. Overview

### 1.1 Defect Rate by Model

**Purpose**: Display defect rate per production model as a bar chart for a specific date

| Step | API | curl |
| ------ | ------ | ------ |
| 1 | work_order | `curl "{{BASE}}/work_order"` |
| 2 | prod_his (by work_order_id) | `curl "{{BASE}}/prod_his?work_order_id=1&limit=500"` |
| 3 | defect_code_mst (labels) | `curl "{{BASE}}/defect_code_mst"` |

**Formula**: `Defect rate(%) = Σ(defect_cnt) / Σ(total_cnt) × 100`

```javascript
const chartData = workOrders.map(wo => {
  const prodList = prodHisByWo[wo.id] || [];
  const total = prodList.reduce((s, p) => s + p.total_cnt, 0);
  const defect = prodList.reduce((s, p) => s + p.defect_cnt, 0);
  return { model: wo.model_name, defectRate: total ? (defect/total*100).toFixed(2) : 0, total, defect };
});
```

---

### 1.2 Defect Rate by Worker

**Purpose**: Bar chart of defect quantity per worker for a specific date/period

| Step | API | curl |
| ------ | ------ | ------ |
| 1 | shift_map | `curl "{{BASE}}/shift_map?work_date=2025-01-01&limit=500"` |
| 2 | worker_mst | `curl "{{BASE}}/worker_mst"` |
| 3 | prod_his (match with shift_map by equip_id) | `curl "{{BASE}}/prod_his?equip_id=1&limit=500"` |
| 4 | defect_his | `curl "{{BASE}}/defect_his?prod_his_id=1"` |

**Logic**: Use shift_map (work_date, worker_id, equip_id) to map worker→equipment for the period, then combine with prod_his (equip_id, time) to aggregate defect_cnt per worker

---

### 1.3 Defect Rate by Worker CSV Download

**Purpose**: Export worker defect data to CSV

**API**: Same as 1.2. Convert aggregated results to CSV on the frontend and trigger download

```javascript
const csv = "Worker,Date,Total,Defect,DefectRate(%)\n" +
  chartData.map(r => `${r.workerName},${r.date},${r.total},${r.defect},${r.defectRate}`).join("\n");
// Use Blob etc. for download
```

---

### 1.4 Equipment Operating Status

**Purpose**: Real-time display of Operating (Green), Stopped (Red), Idle (Orange), Alarm (Blinking Red), Normal Abnormality (Grey)

| API | curl |
| ------ | ------ |
| status_his | `curl "{{BASE}}/status_his?equip_id=1&start_time_from=2025-01-01T00:00:00&start_time_to=2025-01-02T00:00:00&limit=200"` |

**status_code**: `Run`=Operating, `Stop`=Stopped, `Fault`=Fault. Merge with alarm_his to determine alarm status

---

### 1.5 Work Order

**Purpose**: Display order number, item name/code, target quantity, due date, SOP (ERP/MES linked)

| API | curl |
| ------ | ------ |
| work_order | `curl "{{BASE}}/work_order"` |

**Response**: order_no, model_name, target_cnt, start_date, end_date, sop_link

---

### 1.6 Key KPIs

**Purpose**: OEE, real-time good product rate, production progress vs target, current cycle time gauge

| API | curl |
| ------ | ------ |
| kpi_sum | `curl "{{BASE}}/kpi_sum?calc_date=2025-01-01&equip_id=1"` |
| kpi_cfg | `curl "{{BASE}}/kpi_cfg"` (std_cycle_time, target_oee) |

**Response**: availability, performance, quality, oee, uph, mttr, mtbf

> Run KPI calculation: `docker exec hmi-db-postgres psql -U admin -d edge_hmi -c "SELECT core.fn_kpi_sum_calc('2025-01-01'::date);"`

---

### 1.7 Short-term Trend

**Purpose**: Last 24h Gantt-based operating status + main sensor 30-min short-term trend

| API | curl |
| ------ | ------ |
| status_his | `curl "{{BASE}}/status_his?equip_id=1&start_time_from={{NOW-24h}}&start_time_to={{NOW}}"` |
| measurement | `curl "{{BASE}}/measurement?equip_id=1&time_from={{NOW-30m}}&time_to={{NOW}}"` |
| sensor_mst | `curl "{{BASE}}/sensor_mst?equip_id=1"` |

---

### 1.8 Equipment Profile

**Purpose**: Basic info (manufacturing year, main specs, CMMS ID, etc.)

| API | curl |
| ------ | ------ |
| equip_mst | `curl "{{BASE}}/equip_mst/1"` |

**Response**: id, line_id, equip_code, name, type, install_date

---

### 1.9 Equipment Alarm Status

**Purpose**: Intuitive display of alarms (equipment status, sensor status, process conditions) per equipment

| API | curl |
| ------ | ------ |
| alarm_his | `curl "{{BASE}}/alarm_his?equip_id=1&limit=50"` |
| alarm_cfg | `curl "{{BASE}}/alarm_cfg"` |

Join alarm_his.alarm_def_id with alarm_cfg for severity, description

---

## 02. Process & Trend

### 2.1 Standard Work Compliance Monitoring

**Purpose**: Express process items via equipment motor current load patterns

| API | curl |
| ------ | ------ |
| sensor_mst | `curl "{{BASE}}/sensor_mst?equip_id=1"` (identify current sensor) |
| measurement | `curl "{{BASE}}/measurement?equip_id=1&sensor_id=3&time_from=2025-01-01T08:00:00&time_to=2025-01-01T18:00:00"` |

---

### 2.2 Equipment Status Transition Trend

**Purpose**: Visualize Operating→Idle→Stopped→Fault status transition flow

| API | curl |
| ------ | ------ |
| status_his | `curl "{{BASE}}/status_his?equip_id=1&start_time_from=2025-01-01T00:00:00&start_time_to=2025-01-02T00:00:00"` |

**Order**: Build timeline/Gantt by start_time

---

### 2.3 Multi-equipment Comparison View

**Purpose**: Compare main KPI/alarm proportion across identical equipment

| API | curl |
| ------ | ------ |
| kpi_sum | `curl "{{BASE}}/kpi_sum?calc_date=2025-01-01"` |
| alarm_his | `curl "{{BASE}}/alarm_his?equip_id=1"` + equip_id=2, 3 … |

---

### 2.4 Multi-time-series Trend

**Purpose**: Multi-select by period, worker, part number, sensor; charts with zoom/pan

| API | curl |
| ------ | ------ |
| measurement | `curl "{{BASE}}/measurement?equip_id=1&sensor_id=2&time_from=2025-01-01T00:00:00&time_to=2025-01-02T00:00:00&limit=1000"` |

Call in parallel for multiple sensor_id/equip_id, overlay time series on chart

---

### 2.5 4M1E & PQCD Correlation Analysis

**Purpose**: Visualize correlation between Machine/Man/Material/Method changes and Quality/Productivity

| API | Use |
| ------ | ------ |
| prod_his | Productivity (Q), Quality (good rate) |
| defect_his, defect_code_mst | Quality (Q) |
| shift_map, worker_mst | Man |
| parts_mst | Material |
| maint_his | Machine/Method |

Aggregate by period on client, then run correlation analysis/charts

---

### 2.6 Golden Batch Comparison

**Purpose**: Project standard data pattern from normal operation onto chart background, compare deviation with current data

| API | curl |
| ------ | ------ |
| sensor_mst | `curl "{{BASE}}/sensor_mst"` (sensors with is_golden_standard=true) |
| measurement | Golden range: `time_from=..., time_to=...` / Current: `time_from=NOW-1h` |

---

### 2.7 Data Export

**Purpose**: Extract analyzed data to CSV

Convert query API results to CSV. Example: measurement → `time,equip_id,sensor_id,value`

---

### 2.8 Main Process Data Analysis Monitoring

**Purpose**: Visualize analysis patterns and anomalies (hot plate temp, mold vacuum, etc.)

| API | curl |
| ------ | ------ |
| measurement | `curl "{{BASE}}/measurement?equip_id=1&time_from=...&time_to=..."` |
| sensor_mst | `curl "{{BASE}}/sensor_mst?equip_id=1"` (anomaly judgment via lsl, usl) |

---

## 03. Maintenance & Health

### 3.1 Heating Rod Disconnection Monitoring

**Purpose**: Show heating rod disconnection count per station on line equipment layout

| API | curl |
| ------ | ------ |
| measurement, sensor_mst | Domain logic to judge disconnection from heating-rod sensor values (current, resistance, etc.) |

---

### 3.2 Collected Sensor Anomaly Status View

**Purpose**: Display sensor power supply, data collection anomalies, etc.

| API | curl |
| ------ | ------ |
| measurement | Judge collection anomaly by presence/absence of data in last N minutes |
| sensor_mst | `curl "{{BASE}}/sensor_mst"` |

---

### 3.3 Parts Life Cycle

**Purpose**: Visualize consumable usage and replacement cycle (%), advance notice for replacement

| API | curl |
| ------ | ------ |
| parts_mst | `curl "{{BASE}}/parts_mst?equip_id=1"` |

**Formula**: `Usage(%) = current_usage_hours / spec_lifespan_hours * 100`

---

### 3.4 Fault/Repair Timeline

**Purpose**: Timeline from fault occurrence to action completion

| API | curl |
| ------ | ------ |
| maint_his | `curl "{{BASE}}/maint_his?equip_id=1"` |
| alarm_his | `curl "{{BASE}}/alarm_his?equip_id=1"` |

Build timeline from maint_his.start_time, end_time, alarm_his_id

---

### 3.5 Downtime Analysis by Cause

**Purpose**: Pareto by non-operating reason, MTBF, MTTR statistics

| API | curl |
| ------ | ------ |
| kpi_sum | `curl "{{BASE}}/kpi_sum?calc_date=2025-01-01"` (mttr, mtbf) |
| alarm_his, alarm_cfg | Pareto by alarm_code count |

---

### 3.6 Equipment History Card & Life Cycle

**Purpose**: Basic specs, maintenance history, movement/modification, life cycle curve

| API | curl |
| ------ | ------ |
| equip_mst | `curl "{{BASE}}/equip_mst/1"` |
| maint_his | `curl "{{BASE}}/maint_his?equip_id=1"` |

---

### 3.7 Preventive Maintenance (PM) Alert

**Purpose**: Alert for parts replacement and inspection per maintenance schedule

| API | curl |
| ------ | ------ |
| parts_mst | `curl "{{BASE}}/parts_mst"` |
| maint_cfg | `curl "{{BASE}}/maint_cfg"` |

Alert when `current_usage_hours / spec_lifespan_hours` exceeds threshold (e.g. 90%)

---

### 3.8 Sensor Status

**Purpose**: Display sensor connection and data normality

| API | curl |
| ------ | ------ |
| sensor_mst | `curl "{{BASE}}/sensor_mst"` |
| measurement | Presence of recent data (time_from=NOW-5m) |

---

## 04. Production Log

### 4.1 Production Performance Trend

**Purpose**: Bar/line graph of UPH, Lot good rate, average cycle time

| API | curl |
| ------ | ------ |
| kpi_sum | `curl "{{BASE}}/kpi_sum?calc_date=2025-01-01"` (includes uph) |
| prod_his | `curl "{{BASE}}/prod_his?work_order_id=1"` (Lot good rate) |
| kpi_cfg | `curl "{{BASE}}/kpi_cfg"` (std_cycle_time) |

---

### 4.2 Quality Statistics Management

**Purpose**: Mean and standard deviation trend of inspection values (dimension, weight), process capability

| API | curl |
| ------ | ------ |
| measurement | `curl "{{BASE}}/measurement?sensor_id=...&time_from=...&time_to=..."` |
| sensor_mst | lsl, usl (spec) |

Compute mean, std dev on client

---

### 4.3 Defect Cause Analysis

**Purpose**: Pareto chart of defect type frequency by period

| API | curl |
| ------ | ------ |
| defect_his | `curl "{{BASE}}/defect_his?limit=500"` |
| defect_code_mst | `curl "{{BASE}}/defect_code_mst"` |

Sum defect_qty by defect_code_id → sort by frequency → Pareto

```javascript
const byCode = {};
defectHis.forEach(d => { byCode[d.defect_code_id] = (byCode[d.defect_code_id]||0) + d.defect_qty; });
const pareto = Object.entries(byCode).map(([id,qty]) => ({ codeId:id, qty })).sort((a,b)=>b.qty-a.qty);
```

---

### 4.4 Production History Query

**Purpose**: On product/model click, show linked equipment sensor and process conditions at that time

| API | curl |
| ------ | ------ |
| prod_his | `curl "{{BASE}}/prod_his/123"` |
| measurement | `curl "{{BASE}}/measurement?equip_id={{prod.equip_id}}&time_from={{prod.time}}&time_to={{prod.time+10m}}"` |

---

## 99. Settings

### 99.1 Static Management Variables

**Purpose**: Configure IP, Port, Line number, etc.

→ Managed via env vars/config files. No API.

---

### 99.2 Alarm Settings

**Purpose**: Set thresholds and offsets for main sensors

| API | curl |
| ------ | ------ |
| alarm_cfg | `GET/POST/PATCH/DELETE {{BASE}}/alarm_cfg` |
| sensor_mst | `PATCH {{BASE}}/sensor_mst/{id}` (lsl_val, usl_val) |

---

### 99.3 User Permission Management

**Purpose**: Differentiate permissions by worker/engineer/administrator

→ Not implemented in current API. Separate auth/authorization layer required.

---

## Common Parameters

| Parameter | Description | Example |
| ------ | ------ | ------ |
| skip | Number to skip | skip=0 |
| limit | Max count (default 100–500) | limit=500 |
| work_date | YYYY-MM-DD | work_date=2025-01-01 |
| time_from, time_to | ISO 8601 | time_from=2025-01-01T00:00:00%2B09:00 |

> URL encoding: `+` → `%2B`, watch for spaces etc.
