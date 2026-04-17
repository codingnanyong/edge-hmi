#!/usr/bin/env bash
set -euo pipefail

# DB migration runner (order: backup → migrations/*.sql in sorted order).
#
# Usage:
#   DB_URL="postgresql://user:pass@host:5432/dbname" ./db/scripts/migrate.sh
#   # or libpq vars (PGHOST, PGUSER, PGDATABASE, PGPASSWORD), or only POSTGRES_* (Docker/.env)
#
# Environment:
#   SKIP_BACKUP=1         Skip pg_dump before migrate (CI/dev only; not for production)
#   MIGRATE_BACKUP_DIR=   Directory for custom-format dumps (default: <db>/backups)
#
# Docker (이미지 안에서 migrate.sh 실행할 때):
#   로직은 동일 — pg_dump 가 기본 경로에 .dump 를 씁니다. 컨테이너 기본 경로는
#   이미지 종료 시 사라지므로, 백업을 남기려면 볼륨을 마운트하거나 MIGRATE_BACKUP_DIR 을
#   마운트 지점으로 지정하세요.
#   예: docker run --rm -v /data/pg-backups:/opt/edge-hmi/db/backups \\
#         -e DB_URL=postgresql://... edge-hmi-db:tag /opt/edge-hmi/db/scripts/migrate.sh
#
# Requires: psql, pg_dump (unless SKIP_BACKUP=1)
#
# Rollback: automatic DB restore is not performed. On failure, restore the .dump
#   created under MIGRATE_BACKUP_DIR (see message on stderr). Example:
#   pg_restore --clean --if-exists -d "$DB_URL" /path/to/pre_migrate_....dump
#
# Note: files under db/migrations/ are change-only DDL (e.g. renames); full schema
#   is still db/sql/init-db.sql for greenfield installs.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MIG_DIR="${ROOT_DIR}/migrations"
BACKUP_DIR="${MIGRATE_BACKUP_DIR:-${ROOT_DIR}/backups}"
backup_file=""

# libpq는 PG* 만 본다. compose/.env 는 보통 POSTGRES_* 만 있으므로, DB_URL 미사용 시 매핑
if [[ -z "${DB_URL:-}" ]]; then
  export PGUSER="${PGUSER:-${POSTGRES_USER:-}}"
  export PGDATABASE="${PGDATABASE:-${POSTGRES_DB:-}}"
  export PGPASSWORD="${PGPASSWORD:-${POSTGRES_PASSWORD:-}}"
  export PGHOST="${PGHOST:-${POSTGRES_HOST:-127.0.0.1}}"
fi

cleanup_on_exit() {
  local st=$?
  if (( st != 0 )) && [[ -n "${backup_file}" && -f "${backup_file}" ]]; then
    echo "" >&2
    echo "Migration failed (exit ${st}). Roll back by restoring the backup, e.g.:" >&2
    echo "  pg_restore --clean --if-exists -d \"\${DB_URL}\" \"${backup_file}\"" >&2
    echo "  # or set PGHOST/PGUSER/PGDATABASE and: pg_restore --clean --if-exists -f \"${backup_file}\"" >&2
  fi
}
trap cleanup_on_exit EXIT

if ! command -v psql >/dev/null 2>&1; then
  echo "psql not found. Install postgresql-client." >&2
  exit 1
fi

PSQL_BASE=(psql -v ON_ERROR_STOP=1)
if [[ "${DB_URL:-}" != "" ]]; then
  PSQL_BASE+=( "${DB_URL}" )
fi

if [[ "${SKIP_BACKUP:-}" == "1" ]]; then
  echo "WARNING: SKIP_BACKUP=1 — no pre-migration backup. Not recommended for production." >&2
else
  if ! command -v pg_dump >/dev/null 2>&1; then
    echo "pg_dump not found. Install postgresql-client, or set SKIP_BACKUP=1 (at your own risk)." >&2
    exit 1
  fi
  mkdir -p "${BACKUP_DIR}"
  # Named volume mount is often root:root → postgres user cannot write; fall back to /tmp
  if [[ ! -w "${BACKUP_DIR}" ]]; then
    fb="${MIGRATE_BACKUP_DIR_FALLBACK:-/tmp/edge-hmi-db-migrate-backups}"
    mkdir -p "${fb}"
    echo "WARNING: ${BACKUP_DIR} is not writable (e.g. volume owned by root). Using ${fb} for this backup." >&2
    echo "  Fix once: docker compose exec -u root db chown -R postgres:postgres /opt/edge-hmi/db/backups" >&2
    BACKUP_DIR="${fb}"
  fi
  backup_file="${BACKUP_DIR}/pre_migrate_$(date +%Y%m%d_%H%M%S).dump"
  echo "==> DB backup (custom format) -> ${backup_file}"
  if [[ "${DB_URL:-}" != "" ]]; then
    pg_dump -Fc --no-owner --no-acl -f "${backup_file}" "${DB_URL}"
  else
    pg_dump -Fc --no-owner --no-acl -f "${backup_file}"
  fi
  echo "    Backup done."
fi

echo "==> Applying migrations in ${MIG_DIR}"
shopt -s nullglob
files=( "${MIG_DIR}"/*.sql )
shopt -u nullglob
if [[ ${#files[@]} -eq 0 ]]; then
  echo "No *.sql files in ${MIG_DIR}" >&2
  exit 1
fi
for f in "${files[@]}"; do
  echo "==> ${f##*/}"
  "${PSQL_BASE[@]}" -f "${f}"
done

echo "Done."
