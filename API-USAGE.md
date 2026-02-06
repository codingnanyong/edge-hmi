# Edge HMI API Usage

> **Per-feature usage**: See [../FEATURE-USAGE.md](../FEATURE-USAGE.md)

---

## API Overview

Base URL: `http://localhost:8000` (gateway)

| Feature | APIs | Example |
| ------ | ------ | ------ |
| Defect rate by model | work_order, prod_his, defect_code_mst | `GET /work_order`, `GET /prod_his?work_order_id=1` |
| Defect rate by worker | shift_map, worker_mst, prod_his, defect_his | `GET /shift_map?work_date=2025-01-01` |
| Equipment status | status_his | `GET /status_his?equip_id=1&start_time_from=...&start_time_to=...` |
| Work order | work_order | `GET /work_order` |
| Key KPIs | kpi_sum, kpi_cfg | `GET /kpi_sum?calc_date=2025-01-01&equip_id=1` |
| Equipment profile | equip_mst | `GET /equip_mst/1` |
| Alarm status | alarm_his, alarm_cfg | `GET /alarm_his?equip_id=1` |

## Common parameters

| Parameter | Description | Example |
| ------ | ------ | ------ |
| skip | Offset | skip=0 |
| limit | Max rows | limit=500 |
| work_date | YYYY-MM-DD | work_date=2025-01-01 |
| time_from, time_to | ISO 8601 | time_from=2025-01-01T00:00:00 |

## Web UI (gateway :8000)

- `/` — Swagger UI
- `/feature-usage` — Feature usage guide
