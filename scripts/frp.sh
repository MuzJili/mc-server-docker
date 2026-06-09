#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

compose() {
  docker compose -f compose.yaml -f compose.frp.yml "$@"
}

usage() {
  cat <<'USAGE'
Usage: ./scripts/frp.sh <command>

Commands:
  up       Start Sakura Frp client
  down     Stop Sakura Frp client
  restart  Restart Sakura Frp client
  logs     Follow Sakura Frp logs
  status   Show Sakura Frp service status

Before starting, set SAKURA_FRP_TOKEN and SAKURA_FRP_TUNNEL_IDS in .env.
USAGE
}

case "${1:-}" in
  up)
    compose up -d sakura-frpc
    ;;
  down)
    compose stop sakura-frpc
    ;;
  restart)
    compose restart sakura-frpc
    ;;
  logs)
    compose logs -f --tail=200 sakura-frpc
    ;;
  status)
    compose ps sakura-frpc
    ;;
  *)
    usage
    exit 1
    ;;
esac

