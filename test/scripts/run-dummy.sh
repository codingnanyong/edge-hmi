#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${TEST_DIR}"

if [ ! -f .env ]; then
  echo "❌ .env not found. Run: cp .env.example .env"
  exit 1
fi

set -a
. ./.env
set +a

CONTAINER="${DB_CONTAINER:-hmi-db-postgres}"
USER="${POSTGRES_USER:-admin}"
DB="${POSTGRES_DB:-edge_hmi}"

echo "▶ Waiting for DB container (${CONTAINER})..."
for i in $(seq 1 60); do
  if docker exec "${CONTAINER}" pg_isready -U "${USER}" -d "${DB}" &>/dev/null; then
    echo "▶ DB ready."
    break
  fi
  if [ "$i" -eq 60 ]; then
    echo "❌ DB not ready. Run docker compose up -d first."
    exit 1
  fi
  sleep 1
done

echo "▶ Running 00-cleanup.sql..."
docker exec -i "${CONTAINER}" psql -U "${USER}" -d "${DB}" -v ON_ERROR_STOP=1 -f - < sql/00-cleanup.sql

echo "▶ Running 01-dummy-master.sql..."
docker exec -i "${CONTAINER}" psql -U "${USER}" -d "${DB}" -v ON_ERROR_STOP=1 -f - < sql/01-dummy-master.sql

echo "▶ Running 02-dummy-history.sql..."
docker exec -i "${CONTAINER}" psql -U "${USER}" -d "${DB}" -v ON_ERROR_STOP=1 -f - < sql/02-dummy-history.sql

echo "✅ Dummy data loaded."
