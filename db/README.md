# 🗄️ Edge HMI Database

TimescaleDB-based database for industrial monitoring and maintenance systems.

## 🛡️ Data Protection

### Current Configuration

✅ **Safe settings:**

- 📦 Named Volume (`edge_hmi_data`): Data persists even if the container is removed
- 📄 `init-db.sql` runs only on first initialization (skipped if the database already exists)

⚠️ **Data loss risk:**

- `docker compose down -v` removes the volume and causes data loss
- Docker volume removal (`docker volume rm`) causes data loss

### Safe Commands

```bash
# Run from db/. Stop/remove containers only (data preserved)
docker compose down

# Remove containers and networks only (data preserved)
docker compose down --remove-orphans

# ⚠️ DANGER: Remove volumes too (data loss!)
docker compose down -v
```

## 📋 Usage

### 1. ⚙️ Environment Setup

Create `.env` in the `db/` directory. **DB name, user, etc. are set here.** The schema name is defined in `init-db.sql` and must match `POSTGRES_SCHEMA` in `.env`. **Do not commit `.env`** — use a strong password and keep it secret.

```bash
cd db
# Create .env with: POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_SCHEMA, TZ
# Example variable names only — set your own values.
```

- `POSTGRES_DB`: Database name
- `POSTGRES_USER` / `POSTGRES_PASSWORD`: DB credentials (use a strong password)
- `TZ`: Timezone (e.g. `UTC`, `Asia/Seoul`)

### 2. 🚀 Run

```bash
# Run from db/ directory
cd db
docker compose up -d

# View logs
docker compose logs -f edge-hmi-db
```

### 3. 🔌 Connect to Database

Uses `POSTGRES_USER` and `POSTGRES_DB` from `.env`. Replace with your actual user and DB name.

```bash
# Connect from inside container
docker exec -it hmi-db-postgres psql -U $POSTGRES_USER -d $POSTGRES_DB

# Connect from host
psql -h localhost -p 5432 -U $POSTGRES_USER -d $POSTGRES_DB
```

**Schema:**

- DB name = `POSTGRES_DB` from `.env`. Schema = **`core`** (standard). Align with `POSTGRES_SCHEMA=core` in `.env`.
- Tables are created in the `core` schema; `search_path` allows omitting schema name.
- Explicit: `SELECT * FROM core.line_mst;` / Short: `SELECT * FROM line_mst;`

## 📦 Inspect / Extract init-db.sql from Registry Image

On another server with only the pulled image, you can view or extract `init-db.sql`.

Paths in image (run order 01 → 02; pg_cron setup is in the Dockerfile)

- `init-db.sql` → `/docker-entrypoint-initdb.d/01-init-db.sql`
- `kpi-scheduler.sql` → `/docker-entrypoint-initdb.d/02-kpi-scheduler.sql`
- `docker-compose.yml` (reference) → `/opt/edge-hmi-db/docker-compose.yml`

### 1. View in terminal

Set your registry image (e.g. from `.env` or project config). Do not hardcode internal URLs in docs or scripts.

```bash
export IMG="<REGISTRY_HOST>:<PORT>/btx/edge-hmi-db:latest"
docker run --rm ${IMG} cat /docker-entrypoint-initdb.d/01-init-db.sql
```

### 2. Extract to current directory

```bash
docker run --rm $IMG cat /docker-entrypoint-initdb.d/01-init-db.sql > init-db.sql
# In db project: … > sql/init-db.sql
```

## 📊 KPI Summary Scheduler (`kpi_sum`)

`kpi-scheduler.sql` runs right after `init-db.sql` and creates `fn_kpi_sum_calc(p_calc_date DATE)`.

### Function Description

Computes for the given date, per shift_map (shift/line/equip), using `status_his`, `prod_his`, `alarm_his`, `maint_his`, `kpi_cfg`, and stores results in `kpi_sum`:

- **Availability** = Run time / Planned time
- **Performance** = (Output × Standard cycle) / Run time
- **Quality** = Good count / Total count
- **OEE** = Availability × Performance × Quality
- **MTTR** = Mean time to repair (minutes)
- **MTBF** = Run time / Fault count (hours)

### ⏰ Scheduling

**Default: pg_cron** (included in image)

The image includes pg_cron, which automatically runs daily at 01:00 to compute the previous day's KPI.

**Restart after first run:**

```bash
# Restart container after first build/run to apply pg_cron
docker-compose restart
```

**Check pg_cron status:**

```bash
# List registered jobs (jobid, schedule, command). Use your POSTGRES_USER and POSTGRES_DB.
docker exec hmi-db-postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT jobid, schedule, command FROM cron.job;"
```

**Verify job execution:**

pg_cron 1.6 does **not** have `cron.job_run_details`. The run history table exists only in newer/cloud variants.

**KPI job check:** Use presence of rows in `core.kpi_sum` for the given `calc_date`:

```sql
-- Check if yesterday's KPI was computed
SELECT calc_date, COUNT(*) FROM core.kpi_sum WHERE calc_date = CURRENT_DATE - 1 GROUP BY 1;
```

Rows present = job ran for that date. None = not run or no source data (e.g. `shift_map`).

**Manual run:**

```bash
# Compute for a specific date
docker exec hmi-db-postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT fn_kpi_sum_calc('2025-01-25');"

# Compute previous day
docker exec hmi-db-postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT fn_kpi_sum_calc(CURRENT_DATE - 1);"
```

**Alternative: Host cron** (without pg_cron)

If pg_cron is not available, use host cron (use your `POSTGRES_USER` and `POSTGRES_DB`):

```bash
crontab -e
# Add line (compute previous day's KPI at 01:00 daily)
0 1 * * * docker exec hmi-db-postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT fn_kpi_sum_calc(CURRENT_DATE - 1);"
```

## 💾 Backup and Restore

### Backup

```bash
# Database backup (use your POSTGRES_USER and POSTGRES_DB)
docker exec hmi-db-postgres pg_dump -U $POSTGRES_USER $POSTGRES_DB > backup_$(date +%Y%m%d_%H%M%S).sql

# Or volume backup
docker run --rm -v edge-hmi-db_edge_hmi_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/volume_backup_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .
```

### Restore

```bash
# Restore from SQL backup
docker exec -i hmi-db-postgres psql -U $POSTGRES_USER -d $POSTGRES_DB < backup_20240116_120000.sql

# Restore from volume backup (⚠️ existing data will be lost). Run from db/
docker compose down
docker volume rm edge-hmi-db_edge_hmi_data
docker run --rm -v edge-hmi-db_edge_hmi_data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/volume_backup_20240116_120000.tar.gz -C /data
docker compose up -d
```

## 📝 Notes

1. **🚫 Commands to avoid:**

   ```bash
   docker compose down -v  # Removes volume → data loss!
   docker volume rm edge-hmi-db_edge_hmi_data  # Removes volume → data loss!
   ```

2. **Changing init-db.sql when data exists:**
   - `init-db.sql` is applied only on first run
   - For schema changes, write a separate migration script

3. **🔌 Port conflict:**
   - If PostgreSQL is already running locally, port 5432 may conflict
   - Change port in docker-compose.yml: `"5433:5432"`

## 🔍 Volume Inspection

```bash
# List volumes
docker volume ls | grep edge_hmi

# Inspect volume
docker volume inspect edge-hmi-db_edge_hmi_data

# Approximate usage
docker system df -v
```
