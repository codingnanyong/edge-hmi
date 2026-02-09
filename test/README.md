# 🧪 Edge HMI Test

Private Registry pull test environment. All operations run inside this `test/` folder.

- 📦 Pull `btx/edge-hmi*` images from private registry and verify
- 🔨 No build. `.env`, `docker-compose.yml`, `sql/` are inside `test/`

## 📋 Prerequisites

1. **`.env`**  
   Run `cp .env.example .env` and edit if needed.

2. **🔐 Registry login**

   ```bash
   docker login <REGISTRY_HOST>:<PORT>
   ```

   Set your registry address (e.g. from `.env` or project docs). Do not commit internal URLs.

## 🚀 Run

### 1. Compose up (pull from Registry)

```bash
cd test
docker compose pull
docker compose up -d
```

- 🌐 Gateway: [http://localhost:8000]
- 🗄️ DB: localhost:5432 (uses `POSTGRES_*` from `.env`)

### 2. Load dummy data (optional)

After DB is up, run master, history dummy, and `kpi_sum` aggregation:

```bash
cd test
chmod +x scripts/run-dummy.sh
./scripts/run-dummy.sh
```

- `run-dummy.sh` runs psql inside the DB container via `docker exec`. No psql on host needed.
- `00-cleanup.sql` → remove existing dummy data
- `01-dummy-master.sql` → `02-dummy-history.sql` in order
- **measurement**: 200 rows per sensor
- **status_his, prod_his, alarm_his, maint_his, shift_map**: 100+ rows each
- End of `02` calls `fn_kpi_sum_calc` to populate **kpi_sum**

### 3. Manual run (docker exec)

```bash
cd test
docker exec -i hmi-db-postgres psql -U admin -d edge_hmi -v ON_ERROR_STOP=1 -f - < sql/00-cleanup.sql
docker exec -i hmi-db-postgres psql -U admin -d edge_hmi -v ON_ERROR_STOP=1 -f - < sql/01-dummy-master.sql
docker exec -i hmi-db-postgres psql -U admin -d edge_hmi -v ON_ERROR_STOP=1 -f - < sql/02-dummy-history.sql
```

### 4. Update API image version (keep data)

To swap only API images to a new version (e.g. v1.0.2) and **keep DB data**:

1. **Set `API_IMAGE_TAG` in `.env`**

   ```bash
   API_IMAGE_TAG=v1.0.2
   ```

2. **Pull and up**

   ```bash
   cd test
   docker compose pull
   docker compose up -d
   ```

- ⚠️ Do **not** run `down -v` — `edge_hmi_data_test` volume will persist.
- DB image stays `latest`. Only API and gateway use `API_IMAGE_TAG`.

## 📚 Docs

- **FEATURE-USAGE.md** — Feature-to-API usage (overview, endpoints, curl examples, common params). See project root `../FEATURE-USAGE.md`.

## 🛑 Stop & cleanup

```bash
cd test
docker compose down -v
```

Using `-v` removes the `edge_hmi_data_test` volume and deletes DB data.
