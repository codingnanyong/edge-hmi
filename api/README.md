# Edge HMI API

FastAPI + SQLAlchemy. Per-table API (each in its own container) + **hmi-api gateway** that **proxies** requests to these table API containers.

## Structure

```
api/
├── shared/           # config, DB, models (core.*)
├── line_mst/         # Table-specific FastAPI, Dockerfile → dedicated container
├── equip_mst/
├── … (work_order, parts_mst, defect_code_mst, defect_his, kpi_sum, etc.)
├── hmi_api/          # Gateway: no DB. /line_mst, /equip_mst etc. → proxies to respective table containers
│   └── static/
│       ├── html/     # swagger-ui.html, feature-usage.html, docs-ui.html
│       ├── css/
│       └── js/
└── README.md
```

- **Per-table**: One FastAPI per table, DB connection. Each builds to a Docker image → dedicated container.
- **hmi-api**: Gateway image/container. **Proxies** to table API containers. Serves Swagger UI (/, /swagger), **Feature Usage** (/feature-usage), OpenAPI (/openapi.json), /info, /docs.

## Docker Compose (project root)

```bash
cd ~/proj/edge-hmi
docker compose up -d --build
```

| Service    | Port |
|------------|------|
| db         | 5432 |
| **hmi-api**| **8000** |
| line_mst   | 8001 |
| equip_mst  | 8002 |
| sensor_mst | 8003 |
| kpi_sum    | 8004 |
| worker_mst | 8005 |
| shift_cfg  | 8006 |
| kpi_cfg    | 8007 |
| alarm_cfg  | 8008 |
| maint_cfg  | 8009 |
| measurement| 8010 |
| status_his | 8011 |
| prod_his   | 8012 |
| alarm_his  | 8013 |
| maint_his  | 8014 |
| shift_map  | 8015 |
| work_order | 8016 |
| parts_mst  | 8017 |
| defect_code_mst | 8018 |
| defect_his | 8019 |

- **Gateway**: `http://localhost:8000` → hmi-api. `/` (Swagger UI), `/feature-usage` (feature API usage guide), `/docs`→`/`, `/openapi.json`, `/info`, `/health`, `/line_mst`, `/equip_mst`, etc.
- **Direct table access**: `http://localhost:8001/line_mst`, `8002/equip_mst`, … (per-container).

## Local run (DB must be running)

```bash
cd api
cp .env.example .env   # edit if needed
pip install -r line_mst/requirements.txt   # or hmi_api/requirements.txt
export PYTHONPATH="$PWD"
uvicorn line_mst.main:app --reload --port 8001
# or gateway: uvicorn hmi_api.main:app --reload --port 8000
```

## DB connection

- **Host**: `localhost` (local) or `db` (compose)
- **Port**: 5432  
- **Database**: `edge_hmi`  
- **Schema**: `core`

## Private Registry deployment (API images v1.0 / latest)

Build and push each API image to the registry with **v1.0** + **latest** tags.

**Push all:**

```bash
cd ~/proj/edge-hmi/api
./scripts/push-to-registry.sh [registry-url] [version]
```

**Push selected services:**

```bash
./scripts/push-to-registry.sh [registry-url] [version] service1 [service2 ...]
```

- **registry-url** (required): Private Registry address (e.g. `host:5000`). Do not hardcode internal URLs.
- **version** (default `v1.0`): Version tag. `latest` is also updated with the same build
- **services**: one or more of `line_mst`, `equip_mst`, `sensor_mst`, `kpi_sum`, `worker_mst`, `shift_cfg`, `kpi_cfg`, `alarm_cfg`, `maint_cfg`, `work_order`, `parts_mst`, `defect_code_mst`, `measurement`, `status_his`, `prod_his`, `defect_his`, `alarm_his`, `maint_his`, `shift_map`, `hmi-api`

Examples:

```bash
# All (set your registry URL)
./scripts/push-to-registry.sh <REGISTRY_HOST>:<PORT> v1.0

# Gateway only
./scripts/push-to-registry.sh <REGISTRY_HOST>:<PORT> v1.0 hmi-api

# Selected
./scripts/push-to-registry.sh <REGISTRY_HOST>:<PORT> v1.0 line_mst sensor_mst hmi-api
```

Run `docker login <registry-url>` beforehand.
