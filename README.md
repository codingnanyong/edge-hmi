# 🏭 Edge HMI

Edge HMI monitoring & maintenance system. DB + API architecture.

## 📁 Structure

```text
edge-hmi/
├── README.md                    # This file
├── FEATURE-USAGE.md             # Feature-to-API usage guide (reference doc)
├── docker-compose.yml           # DB + table APIs + hmi-api gateway (container orchestration)
├── docker-compose.registry.yml  # Private Registry images
├── db/                          # TimescaleDB (schema, KPI scheduler)
│   ├── README.md
│   ├── dockerfile
│   ├── sql/
│   │   ├── init-db.sql
│   │   └── kpi-scheduler.sql
│   └── scripts/
│       └── push-to-registry.sh
├── api/                         # FastAPI + SQLAlchemy
    ├── shared/                  # config, DB, models
    ├── line_mst/                # Table APIs (each runs in a container)
    ├── equip_mst/
    ├── … (work_order, parts_mst, defect_code_mst, defect_his, etc.)
    ├── kpi_sum/
    ├── hmi_api/                 # Gateway: proxies to table API containers
    │   ├── static/
    │   │   ├── html/            # swagger-ui, feature-usage, docs-ui
    │   │   ├── css/
    │   │   └── js/              # feature-usage-data.js, swagger-init, etc.
    │   └── …
    ├── scripts/
    │   └── push-to-registry.sh
    └── README.md
└── test/                       # Private Registry pull test
    ├── README.md
    ├── docker-compose.yml
    ├── sql/
    │   ├── 00-cleanup.sql
    │   ├── 01-dummy-master.sql
    │   └── 02-dummy-history.sql
    └── scripts/
        └── run-dummy.sh
```

## 🚀 Quick Start

**DB only**

```bash
cd db
# Create .env (POSTGRES_*, POSTGRES_SCHEMA=core, TZ). See db/README.md
docker compose up -d
```

**DB + table APIs + hmi-api gateway** (project root)

```bash
# db/.env required
docker compose up -d --build
```

- DB: 5432, **hmi-api (gateway): 8000** (Swagger UI `/`, Feature Usage `/feature-usage`), line_mst: 8001 … defect_his: 8019 (details → **api/README.md**)

## 📤 Deployment (Private Registry)

Use `api/scripts/push-to-registry.sh` to build and push API images to Private Registry.

```bash
cd api
./scripts/push-to-registry.sh [registry-url] [version]   # All
./scripts/push-to-registry.sh [registry-url] [version] hmi-api line_mst   # Selected
```

- **registry-url**: default `localhost`
- **version**: default `v1.0`. `latest` is also updated with the same build
- Local built images are rmi'd and build cache pruned after push

Details & service list → **api/README.md**

## 🧪 Test (Private Registry pull)

Use `test/` to pull images from the registry and run with dummy data (no local build).

```bash
cd test
cp .env.example .env   # edit if needed
docker login localhost
docker compose pull
docker compose up -d
./scripts/run-dummy.sh   # optional: load dummy data
```

- Gateway: [http://localhost:8000]
- DB: localhost:5432

Details → **test/README.md**

## 🌐 Web UI (hmi-api gateway :8000)

| Path | Description |
| ------ | ------ |
| `/` | Swagger UI (aggregated API docs) |
| `/swagger` | Same as `/` |
| `/feature-usage` | Feature API usage guide (how to use each feature) |
| `/openapi.json` | Aggregated OpenAPI spec |

## 📂 Git Repository

- **Remote**: `http://{localhost}/{Repository}`
- **Default branch**: `main`
- **Integration branch**: `develop` (merge features, then PR to main)

### **Branch workflow**

```bash
git checkout develop && git pull
git checkout -b feature/issue-name   # e.g. feature/api-auth, fix/db-init
# Work...
git add -A && git commit -m "Message"
git push -u origin feature/issue-name
# Create PR on remote → merge to develop
# Optionally develop → main PR merge
```

**Release (tag)** — after main merge

```bash
git checkout main && git pull origin main
git tag -a {version} -m "Release {version}: Summary"
git push origin{ version}
```

Create **Releases** from the tag on remote (Gitea, etc.) if desired.

---

- 📊 DB details: **db/README.md**
- 🔌 API details: **api/README.md**
- 🧪 Test (Registry pull): **test/README.md**