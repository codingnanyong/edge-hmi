#!/bin/bash
set -e

# ============================================================================
# Push Edge HMI API Docker Images to Private Registry
# ============================================================================
# Builds and pushes each API image with [version] and latest.
# latest is always updated to this build.
#
# Usage:
#   ./scripts/push-to-registry.sh [registry-url] [version]              # push ALL
#   ./scripts/push-to-registry.sh [registry-url] [version] line_mst      # push one
#   ./scripts/push-to-registry.sh [registry-url] [version] line_mst sensor_mst hmi-api  # push several
#
# Examples:
#   ./scripts/push-to-registry.sh 203.228.107.184:5000 v1.0
#   ./scripts/push-to-registry.sh 203.228.107.184:5000 v1.0 hmi-api
#   ./scripts/push-to-registry.sh 203.228.107.184:5000 v1.0 line_mst equip_mst
# ============================================================================

REGISTRY_URL="${1:?Usage: $0 <REGISTRY_HOST>:<PORT> [version] [service ...]}"
VERSION="${2:-latest}"
if [ $# -ge 2 ]; then
  shift 2
  REQUESTED=("$@")
else
  REQUESTED=()
fi

# key => "dockerfile:image_name"
# Table APIs: key = service dir; gateway: key = hmi-api
declare -A API_MAP=(
  [line_mst]="line_mst/Dockerfile:btx/edge-hmi-api-line-mst"
  [equip_mst]="equip_mst/Dockerfile:btx/edge-hmi-api-equip-mst"
  [sensor_mst]="sensor_mst/Dockerfile:btx/edge-hmi-api-sensor-mst"
  [kpi_sum]="kpi_sum/Dockerfile:btx/edge-hmi-api-kpi-sum"
  [worker_mst]="worker_mst/Dockerfile:btx/edge-hmi-api-worker-mst"
  [shift_cfg]="shift_cfg/Dockerfile:btx/edge-hmi-api-shift-cfg"
  [kpi_cfg]="kpi_cfg/Dockerfile:btx/edge-hmi-api-kpi-cfg"
  [alarm_cfg]="alarm_cfg/Dockerfile:btx/edge-hmi-api-alarm-cfg"
  [maint_cfg]="maint_cfg/Dockerfile:btx/edge-hmi-api-maint-cfg"
  [measurement]="measurement/Dockerfile:btx/edge-hmi-api-measurement"
  [equip_status]="equip_status/Dockerfile:btx/edge-hmi-api-equip-status"
  [prod_his]="prod_his/Dockerfile:btx/edge-hmi-api-prod-his"
  [alarm_his]="alarm_his/Dockerfile:btx/edge-hmi-api-alarm-his"
  [maint_his]="maint_his/Dockerfile:btx/edge-hmi-api-maint-his"
  [shift_map]="shift_map/Dockerfile:btx/edge-hmi-api-shift-map"
  [hmi-api]="hmi_api/Dockerfile:btx/edge-hmi-api"
  [hmi-web]="web/Dockerfile:btx/edge-hmi-web"
  [work_order]="work_order/Dockerfile:btx/edge-hmi-api-work-order"
  [defect_code_mst]="defect_code_mst/Dockerfile:btx/edge-hmi-api-defect-code-mst"
  [defect_his]="defect_his/Dockerfile:btx/edge-hmi-api-defect-his"
  [parts_mst]="parts_mst/Dockerfile:btx/edge-hmi-api-parts-mst"
)

ALL_KEYS=(line_mst equip_mst sensor_mst kpi_sum worker_mst shift_cfg kpi_cfg alarm_cfg maint_cfg measurement status_his prod_his alarm_his maint_his shift_map hmi-api)

resolve_targets() {
  if [ ${#REQUESTED[@]} -eq 0 ]; then
    TARGETS=("${ALL_KEYS[@]}")
    return
  fi
  TARGETS=()
  for k in "${REQUESTED[@]}"; do
    if [[ -n "${API_MAP[$k]:-}" ]]; then
      TARGETS+=("$k")
    else
      echo "❌ Unknown service: $k"
      echo "   Valid: ${ALL_KEYS[*]}"
      exit 1
    fi
  done
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT_DIR="$(cd "${API_DIR}/.." && pwd)"

resolve_targets

echo "============================================================================"
echo "🐳 Edge HMI API — Build & Push to Private Registry"
echo "============================================================================"
echo "Registry:  ${REGISTRY_URL}"
echo "Version:   ${VERSION} (+ latest)"
echo "Services:  ${TARGETS[*]}"
echo ""

echo "📋 Checking shared & Dockerfiles..."
[ -d "${API_DIR}/shared" ] || { echo "❌ Missing: api/shared"; exit 1; }
for k in "${TARGETS[@]}"; do
  df="${API_MAP[$k]%%:*}"
  if [[ "$k" == "hmi-web" ]]; then
    [ -f "${ROOT_DIR}/${df}" ] || { echo "❌ Missing: ${df} (in project root)"; exit 1; }
  else
    [ -f "${API_DIR}/${df}" ] || { echo "❌ Missing: $df"; exit 1; }
  fi
done
echo "✅ OK"
echo ""

push_one() {
  local dockerfile="$1"
  local image_name="$2"
  local full_image="${REGISTRY_URL}/${image_name}:${VERSION}"
  local latest_image="${REGISTRY_URL}/${image_name}:latest"

  echo "----------------------------------------"
  echo "🔨 Build: ${image_name}"
  if [[ "$image_name" == "btx/edge-hmi-web" ]]; then
    (cd "${ROOT_DIR}" && docker build -t "${full_image}" -f "${dockerfile}" .)
  else
    (cd "${API_DIR}" && docker build -t "${full_image}" -f "${dockerfile}" .)
  fi
  echo "🏷️  Tag: ${latest_image}"
  docker tag "${full_image}" "${latest_image}"

  echo "📤 Push: ${full_image}"
  docker push "${full_image}" || { echo "❌ Push failed. Try: docker login ${REGISTRY_URL}"; return 1; }
  echo "📤 Push: ${latest_image}"
  docker push "${latest_image}" || { echo "❌ Push latest failed"; return 1; }
  echo "🗑️  Rmi local: ${image_name}"
  docker rmi "${full_image}" "${latest_image}" 2>/dev/null || true
  echo "✅ ${image_name} done"
  echo ""
}

for k in "${TARGETS[@]}"; do
  entry="${API_MAP[$k]}"
  push_one "${entry%%:*}" "${entry##*:}"
done

echo "============================================================================"
echo "✅ Pushed ${#TARGETS[@]} image(s): ${VERSION} + latest"
echo "============================================================================"
echo ""
echo "🧹 Docker build cache prune..."
docker builder prune -af
echo "✅ Cache cleared"
echo ""
echo "Pull examples:"
echo "  docker pull ${REGISTRY_URL}/btx/edge-hmi-api:${VERSION}"
echo "  docker pull ${REGISTRY_URL}/btx/edge-hmi-api-line-mst:${VERSION}"
echo "  docker pull ${REGISTRY_URL}/btx/edge-hmi-api:latest"
echo ""
