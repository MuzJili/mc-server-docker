#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST_DIR="${1:-$ROOT_DIR/host-software}"

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

install_major_apps() {
  local file="$MANIFEST_DIR/major-apps.tsv"
  local name kind method package version note
  local apt_packages=()

  if [[ ! -s "$file" ]]; then
    echo "Major app manifest not found: $file" >&2
    return
  fi

  while IFS=$'\t' read -r name kind method package version note; do
    [[ -z "${name:-}" || "$name" == \#* ]] && continue
    case "$method" in
      apt)
        apt_packages+=("$package")
        ;;
      official-script)
        echo "Skipping $name here: handled by bootstrap or official installer. ${note:-}"
        ;;
      manual)
        echo "Manual app: $name. ${note:-}"
        ;;
      *)
        echo "Unknown install method for $name: $method" >&2
        ;;
    esac
  done < "$file"

  if [[ "${#apt_packages[@]}" -gt 0 ]]; then
    if ! need_cmd apt-get; then
      echo "apt-get is not available; skipping apt apps: ${apt_packages[*]}" >&2
      return
    fi

    echo "Installing curated apt apps: ${apt_packages[*]}"
    as_root apt-get update
    for package in "${apt_packages[@]}"; do
      if dpkg-query -W "$package" >/dev/null 2>&1; then
        echo "Already installed: $package"
        continue
      fi
      as_root apt-get install -y "$package" || {
        echo "Could not install $package from apt. Use the official .deb/source if this is a third-party app." >&2
      }
    done
  fi
}

install_vscode_extensions() {
  local file="$MANIFEST_DIR/vscode-extensions.txt"
  if [[ ! -s "$file" ]]; then
    return
  fi

  if ! need_cmd code; then
    echo "VS Code CLI 'code' is not installed; skipping VS Code extensions." >&2
    return
  fi

  echo "Installing VS Code extensions from $file..."
  while IFS= read -r extension; do
    [[ -z "$extension" || "$extension" == \#* ]] && continue
    code --install-extension "$extension"
  done < "$file"
}

pull_docker_images() {
  local file="$MANIFEST_DIR/docker-images.txt"
  if [[ ! -s "$file" ]]; then
    return
  fi

  if ! need_cmd docker; then
    echo "docker is not installed; skipping Docker image pre-pull." >&2
    return
  fi

  echo "Pulling high-level Docker images from $file..."
  while IFS= read -r image; do
    [[ -z "$image" || "$image" == \#* ]] && continue
    docker image inspect "$image" >/dev/null 2>&1 || docker pull "$image" || true
  done < "$file"
}

if [[ ! -d "$MANIFEST_DIR" ]]; then
  echo "Host software manifest directory not found: $MANIFEST_DIR" >&2
  exit 1
fi

install_major_apps
install_vscode_extensions
pull_docker_images

echo "Curated host software installation pass finished."
