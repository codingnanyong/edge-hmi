#!/bin/bash
set -e

# ============================================================================
# Push Docker Image to Private Registry
# ============================================================================
# Pushes both [tag] and latest; latest is always updated to this build.
# Usage: ./scripts/push-to-registry.sh [registry-url] [tag]
# Example: ./scripts/push-to-registry.sh <REGISTRY_HOST>:<PORT> v1.0
# ============================================================================

REGISTRY_URL="${1:?Usage: $0 <REGISTRY_HOST>:<PORT> [tag]}"
IMAGE_TAG="${2:-latest}"
IMAGE_NAME="btx/edge-hmi-db"
FULL_IMAGE="${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "============================================================================"
echo "🐳 Build & Push to Private Registry"
echo "============================================================================"
echo "Registry: ${REGISTRY_URL}"
echo "Image:    ${FULL_IMAGE}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_DIR}"

echo "📋 Checking required files..."
for f in dockerfile sql/init-db.sql sql/kpi-scheduler.sql; do
    if [ ! -e "$f" ]; then
        echo "❌ Missing: $f"
        exit 1
    fi
done
echo "✅ OK"
echo ""

echo "🔨 Building..."
docker build -t "${FULL_IMAGE}" -f dockerfile .
echo "✅ Build done"
echo ""

# Always tag same image as latest (so latest is always updated)
LATEST_IMAGE="${REGISTRY_URL}/${IMAGE_NAME}:latest"
if [ "${IMAGE_TAG}" != "latest" ]; then
    echo "🏷️  Tagging as latest..."
    docker tag "${FULL_IMAGE}" "${LATEST_IMAGE}"
fi

echo "📤 Pushing..."
docker push "${FULL_IMAGE}" || {
    echo "❌ Push failed. Try: docker login ${REGISTRY_URL}"
    exit 1
}
if [ "${IMAGE_TAG}" != "latest" ]; then
    docker push "${LATEST_IMAGE}" || { echo "❌ Push latest failed"; exit 1; }
fi

echo ""
echo "============================================================================"
echo "✅ Pushed: ${FULL_IMAGE}"
if [ "${IMAGE_TAG}" != "latest" ]; then
    echo "✅ Pushed: ${LATEST_IMAGE} (always updated)"
fi
echo "============================================================================"
echo ""
echo "🗑️  Rmi local images..."
docker rmi "${FULL_IMAGE}" 2>/dev/null || true
if [ "${IMAGE_TAG}" != "latest" ]; then
    docker rmi "${LATEST_IMAGE}" 2>/dev/null || true
fi
echo "✅ Local images removed"
echo ""
echo "Pull: docker pull ${FULL_IMAGE}"
echo "      docker pull ${LATEST_IMAGE}"
echo "Create .env (POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_SCHEMA, TZ) on target."
echo ""
