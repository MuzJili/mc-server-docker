#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

compose() {
  docker compose -f compose.yaml "$@"
}

usage() {
  cat <<'USAGE'
Usage: ./scripts/mcsm.sh <command>

Commands:
  init       Generate .env and persistent directories
  pull       Pull MCSManager images
  up         Start MCSManager Web + Daemon
  down       Stop MCSManager Web + Daemon
  restart    Restart MCSManager Web + Daemon
  logs       Follow MCSManager logs
  status     Show service status
  key        Print daemon key/config path and node address guidance
USAGE
}

load_env_root() {
  if [[ -f .env ]]; then
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
  fi
  : "${MCSM_ROOT:=}"
}

case "${1:-}" in
  init)
    ./scripts/init-env.sh
    ;;
  pull)
    compose pull
    ;;
  up)
    compose up -d
    ;;
  down)
    compose down
    ;;
  restart)
    compose restart
    ;;
  logs)
    compose logs -f --tail=200
    ;;
  status)
    compose ps
    ;;
  key)
    load_env_root
    if [[ -z "$MCSM_ROOT" ]]; then
      echo "MCSM_ROOT is not set. Run ./scripts/init-env.sh first." >&2
      exit 1
    fi
    CONFIG_FILE="$MCSM_ROOT/mcsmanager/daemon/data/Config/global.json"
    if [[ ! -f "$CONFIG_FILE" ]]; then
      echo "Daemon config not found yet: $CONFIG_FILE" >&2
      echo "Start the stack once, then run this command again." >&2
      exit 1
    fi
    echo "Daemon config file:"
    echo "  $CONFIG_FILE"
    echo
    echo "Possible daemon key fields:"
    sed -nE 's/.*"(key|apiKey|apikey|secret|token)"[[:space:]]*:[[:space:]]*"([^"]+)".*/  \1 = \2/p' "$CONFIG_FILE" || true
    echo
    echo "Raw config:"
    cat "$CONFIG_FILE"
    echo
    echo
    echo "Node address guidance:"
    echo "  Recommended on LAN: address=<NUC_LAN_IP>, port=${MCSM_DAEMON_PORT:-24444}"
    echo "  Optional through Sakura Frp: address=<Daemon tunnel host>, port=<Daemon tunnel remote port>"
    echo "  Localhost is only for NUC-browser testing: address=127.0.0.1, port=${MCSM_DAEMON_PORT:-24444}"
    echo
    echo "Do not use 127.0.0.1 as a long-term node address for Docker-separated Web/Daemon."
    ;;
  *)
    usage
    exit 1
    ;;
esac
