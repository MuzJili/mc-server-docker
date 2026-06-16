#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

INSTALL_DOCKER="${INSTALL_DOCKER:-1}"
INSTALL_CODEX="${INSTALL_CODEX:-1}"
INSTALL_SAKURA_FRP="${INSTALL_SAKURA_FRP:-0}"
INSTALL_HOST_SOFTWARE="${INSTALL_HOST_SOFTWARE:-0}"
HOST_SOFTWARE_DIR="${HOST_SOFTWARE_DIR:-$ROOT_DIR/host-software}"
START_MCSM="${START_MCSM:-1}"
SAKURA_FRP_DIRECT="${SAKURA_FRP_DIRECT:-0}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

as_root() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

detect_pkg_manager() {
  if need_cmd apt-get; then
    echo apt
  elif need_cmd dnf; then
    echo dnf
  elif need_cmd yum; then
    echo yum
  elif need_cmd pacman; then
    echo pacman
  else
    echo unknown
  fi
}

install_base_packages() {
  local manager
  manager="$(detect_pkg_manager)"

  case "$manager" in
    apt)
      as_root apt-get update
      as_root apt-get install -y ca-certificates curl wget git gnupg lsb-release zstd tar rsync jq
      ;;
    dnf)
      as_root dnf install -y ca-certificates curl wget git gnupg zstd tar rsync jq
      ;;
    yum)
      as_root yum install -y ca-certificates curl wget git gnupg zstd tar rsync jq
      ;;
    pacman)
      as_root pacman -Sy --needed --noconfirm ca-certificates curl wget git gnupg zstd tar rsync jq
      ;;
    *)
      echo "Unsupported package manager. Install these manually: curl wget git zstd tar rsync jq" >&2
      ;;
  esac
}

install_docker_if_needed() {
  if need_cmd docker && docker compose version >/dev/null 2>&1; then
    echo "Docker and Docker Compose are already available."
    return
  fi

  echo "Installing Docker with Docker's official convenience script..."
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  as_root sh /tmp/get-docker.sh
  rm -f /tmp/get-docker.sh

  as_root systemctl enable --now docker || true

  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    as_root usermod -aG docker "$USER" || true
    echo "Current user was added to the docker group. Log out and back in if docker needs sudo."
  fi
}

install_codex_if_requested() {
  if [[ "$INSTALL_CODEX" != "1" ]]; then
    return
  fi

  if need_cmd codex; then
    echo "Codex is already available: $(command -v codex)"
    return
  fi

  echo "Installing Codex CLI with the official unattended installer..."
  curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh

  if ! need_cmd codex; then
    echo "Codex installed, but it is not on PATH in this shell yet." >&2
    echo "Open a new terminal or add the installer output path to PATH, then run: codex" >&2
  fi
}

install_sakura_frp_if_requested() {
  if [[ "$INSTALL_SAKURA_FRP" != "1" ]]; then
    return
  fi

  echo "Installing SakuraFrp Launcher with the official Linux script..."
  if [[ "$SAKURA_FRP_DIRECT" == "1" ]]; then
    as_root bash -c '. <(curl -sSL https://doc.natfrp.com/launcher.sh) direct'
  else
    as_root bash -c '. <(curl -sSL https://doc.natfrp.com/launcher.sh)'
  fi
}

install_host_software_if_requested() {
  if [[ "$INSTALL_HOST_SOFTWARE" != "1" ]]; then
    return
  fi

  ./scripts/install-host-software.sh "$HOST_SOFTWARE_DIR"
}

init_project_env() {
  if [[ ! -f .env ]]; then
    ./scripts/init-env.sh
  else
    echo ".env already exists. Keeping it unchanged."
    mkdir -p data/mcsmanager/web/data data/mcsmanager/web/logs data/mcsmanager/daemon/data data/mcsmanager/daemon/logs instances
  fi
}

start_mcsm_if_requested() {
  if [[ "$START_MCSM" != "1" ]]; then
    return
  fi

  ./scripts/mcsm.sh pull
  ./scripts/mcsm.sh up
}

print_next_steps() {
  cat <<'NEXT'

Bootstrap finished.

Next steps:
  1. Open MCSManager at http://<this-host-lan-ip>:23333
  2. Run ./scripts/mcsm.sh key after first startup to get the daemon key.
  3. Add the daemon node in MCSManager:
     address=<this-host-lan-ip>, port=24444, key=<daemon key>
  4. Run codex and sign in if Codex was installed for the first time.
  5. If using SakuraFrp Launcher, open its WebUI or remote management and enable tunnels for:
     23333/tcp, 24444/tcp, and each game instance port.

Useful commands:
  ./scripts/mcsm.sh status
  ./scripts/mcsm.sh logs
  ./scripts/mcsm.sh key
NEXT
}

install_base_packages
if [[ "$INSTALL_DOCKER" == "1" ]]; then
  install_docker_if_needed
fi
install_codex_if_requested
install_sakura_frp_if_requested
install_host_software_if_requested
init_project_env
start_mcsm_if_requested
print_next_steps
