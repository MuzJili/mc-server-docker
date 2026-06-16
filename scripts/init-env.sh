#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
EXAMPLE_FILE="$ROOT_DIR/.env.example"
DATA_ROOT="$ROOT_DIR/data"
INSTANCE_ROOT="$ROOT_DIR/instances"
FORCE=0

usage() {
  cat <<'USAGE'
Usage: ./scripts/init-env.sh [--force]

Without --force, keep an existing .env and ensure its data directories exist.
With --force, regenerate .env from .env.example, preserving non-path local settings.
USAGE
}

case "${1:-}" in
  "")
    ;;
  --force)
    FORCE=1
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

ensure_dirs() {
  local data_root="$1"
  local instance_root="$2"

  mkdir -p \
    "$data_root/mcsmanager/web/data" \
    "$data_root/mcsmanager/web/logs" \
    "$data_root/mcsmanager/daemon/data" \
    "$data_root/mcsmanager/daemon/logs" \
    "$instance_root"
}

env_value() {
  local file="$1"
  local key="$2"

  awk -F= -v key="$key" '
    $0 ~ "^[[:space:]]*" key "=" {
      sub(/^[[:space:]]*[^=]*=/, "")
      print
      found = 1
      exit
    }
    END {
      if (!found) {
        exit 1
      }
    }
  ' "$file"
}

set_env_value() {
  local file="$1"
  local key="$2"
  local value="$3"
  local tmp_file

  tmp_file="$(mktemp)"
  awk -v key="$key" -v value="$value" '
    BEGIN { replaced = 0 }
    $0 ~ "^" key "=" {
      print key "=" value
      replaced = 1
      next
    }
    { print }
    END {
      if (!replaced) {
        print key "=" value
      }
    }
  ' "$file" > "$tmp_file"
  mv "$tmp_file" "$file"
}

if [[ -f "$ENV_FILE" && "$FORCE" != "1" ]]; then
  current_data_root="$(env_value "$ENV_FILE" MCSM_ROOT || true)"
  current_instance_root="$(env_value "$ENV_FILE" MCSM_INSTANCE_ROOT || true)"
  current_data_root="${current_data_root:-$DATA_ROOT}"
  current_instance_root="${current_instance_root:-$INSTANCE_ROOT}"

  ensure_dirs "$current_data_root" "$current_instance_root"

  echo ".env already exists: $ENV_FILE"
  echo "Kept it unchanged and ensured its data directories exist."
  echo "Use ./scripts/init-env.sh --force to regenerate it from .env.example."
  echo "Persistent data root: $current_data_root"
  echo "MCSManager instance root: $current_instance_root"
  exit 0
fi

TMP_ENV="$(mktemp)"
awk -v root="$DATA_ROOT" -v instance_root="$INSTANCE_ROOT" '
  /^MCSM_ROOT=/ { print "MCSM_ROOT=" root; next }
  /^MCSM_INSTANCE_ROOT=/ { print "MCSM_INSTANCE_ROOT=" instance_root; next }
  { print }
' "$EXAMPLE_FILE" > "$TMP_ENV"

if [[ -f "$ENV_FILE" ]]; then
  for key in \
    COMPOSE_PROJECT_NAME \
    MCSM_IMAGE_TAG \
    MCSM_WEB_BIND \
    MCSM_WEB_PORT \
    MCSM_DAEMON_BIND \
    MCSM_DAEMON_PORT \
    GAME_NETWORK_NAME \
    LOG_MAX_SIZE \
    LOG_MAX_FILE
  do
    if value="$(env_value "$ENV_FILE" "$key")"; then
      set_env_value "$TMP_ENV" "$key" "$value"
    fi
  done
fi

mv "$TMP_ENV" "$ENV_FILE"

ensure_dirs "$DATA_ROOT" "$INSTANCE_ROOT"

echo "Generated $ENV_FILE"
echo "Persistent data root: $DATA_ROOT"
echo "MCSManager instance root: $INSTANCE_ROOT"
echo "Only management directories were created. Build game instances manually in MCSManager."
