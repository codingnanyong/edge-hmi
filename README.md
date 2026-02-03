# Edge HMI

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue?logo=python&logoColor=white)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![TimescaleDB](https://img.shields.io/badge/TimescaleDB-PostgreSQL-336791?logo=postgresql&logoColor=white)](https://www.timescale.com/)

Edge HMI monitoring and maintenance system. DB + API architecture.

## Structure

```text
edge-hmi/
├── README.md         # This file
├── docker-compose.yml # DB + per-table APIs + hmi-api gateway (container links)
├── db/               # TimescaleDB (schema, KPI scheduler)
│   └── README.md
└── api/              # FastAPI + SQLAlchemy
    ├── shared/       # config, DB, models
    ├── line_mst/     # Per-table API (each as a container)
    ├── equip_mst/
    ├── sensor_mst/
    ├── worker_mst/
    ├── shift_cfg/
    ├── kpi_cfg/
    ├── alarm_cfg/
    ├── maint_cfg/
    ├── measurement/
    ├── status_his/
    ├── prod_his/
    ├── alarm_his/
    ├── maint_his/
    ├── shift_map/
    ├── kpi_sum/
    ├── hmi_api/      # Gateway: proxies to table API containers
    └── README.md
```

## Quick Start

### **DB only**

```bash
cd db
# Create .env (POSTGRES_*, POSTGRES_SCHEMA=core, TZ). See db/README.md
docker compose up -d
```

**DB + per-table APIs + hmi-api gateway** (project root)

```bash
# db/.env required
docker compose up -d --build
```

- DB: 5432, hmi-api (gateway): 8000, line_mst: 8001 … kpi_sum: 8004, worker_mst: 8005 … shift_map: 8015 (see api/README.md)

**API details**  
→ See `api/README.md`.

## Git Repository

- **Remote**: `http://<GITEA_HOST>:3000/<namespace>/edge-hmi.git`
- **Default branch**: `main`

**Branch workflow** (for features/fixes):

```bash
git checkout main && git pull
git checkout -b feature/issue-name   # e.g. feature/api-auth, fix/db-init
# After changes
git add -A && git commit -m "message"
git push -u origin feature/issue-name
# Open MR/PR on remote → merge to main
```

---

- DB details: **db/README.md**
- API details: **api/README.md**
