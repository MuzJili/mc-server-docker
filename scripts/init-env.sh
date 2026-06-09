#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
EXAMPLE_FILE="$ROOT_DIR/.env.example"
DATA_ROOT="$ROOT_DIR/data"
INSTANCE_ROOT="$ROOT_DIR/instances"

if [[ -f "$ENV_FILE" && "${1:-}" != "--force" ]]; then
  echo ".env already exists: $ENV_FILE"
  echo "Use ./scripts/init-env.sh --force to regenerate it."
  exit 0
fi

awk -v root="$DATA_ROOT" -v instance_root="$INSTANCE_ROOT" '
  /^MCSM_ROOT=/ { print "MCSM_ROOT=" root; next }
  /^MCSM_INSTANCE_ROOT=/ { print "MCSM_INSTANCE_ROOT=" instance_root; next }
  { print }
' "$EXAMPLE_FILE" > "$ENV_FILE"

mkdir -p \
  "$DATA_ROOT/mcsmanager/web/data" \
  "$DATA_ROOT/mcsmanager/web/logs" \
  "$DATA_ROOT/mcsmanager/daemon/data" \
  "$DATA_ROOT/mcsmanager/daemon/logs" \
  "$INSTANCE_ROOT"

echo "Generated $ENV_FILE"
echo "Persistent data root: $DATA_ROOT"
echo "MCSManager instance root: $INSTANCE_ROOT"
echo "Only management directories were created. Build game instances manually in MCSManager."
