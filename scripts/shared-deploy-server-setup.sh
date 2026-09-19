#!/usr/bin/env bash
# shared-deploy-server-setup.sh
#
# Turns a server that already has baseline infra (../server-setup.sh —
# Docker, Caddy, /opt/stacks, Dockge) into a shared multi-user deploy
# machine: installs the docker-escape-watch backstop.
#
# This is a separate layer on purpose — not every server with Docker on it
# is meant to have multiple deploy accounts in the docker group. Only run
# this on boxes like lando/vader/leia where several people deploy.
#
# After this, provision each deploy account with:
#   sudo ./oracle-vm-setup.sh <username> deploy [ssh-source-user]
#
# Usage: sudo ./shared-deploy-server-setup.sh

set -euo pipefail

info()  { printf "\033[1;34m▸ %s\033[0m\n" "$*"; }
error() { printf "\033[1;31m✗ %s\033[0m\n" "$*"; exit 1; }

[[ "$(uname -s)" == "Linux" ]] || error "This script is Linux-only"
command -v docker &>/dev/null || error "Docker not found — run server-setup.sh first"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# ─── docker-escape-watch (detection backstop) ────────
install_escape_watch() {
  if systemctl is-active --quiet docker-escape-watch 2>/dev/null; then
    info "docker-escape-watch already running"
    return
  fi

  info "Installing docker-escape-watch..."
  sudo cp "$SCRIPT_DIR/docker-escape-watch.sh" /usr/local/sbin/docker-escape-watch
  sudo chown root:root /usr/local/sbin/docker-escape-watch
  sudo chmod 755 /usr/local/sbin/docker-escape-watch

  sudo cp "$SCRIPT_DIR/docker-escape-watch.service" /etc/systemd/system/docker-escape-watch.service
  sudo systemctl daemon-reload
  sudo systemctl enable --now docker-escape-watch

  info "Verifying it actually fires..."
  sudo docker run --rm -d --name escape-watch-selftest -v /:/host alpine sleep 1 &>/dev/null
  sleep 2
  if sudo journalctl -t docker-escape-watch -n 5 --no-pager | grep -q SUSPICIOUS; then
    info "docker-escape-watch verified working"
  else
    echo "⚠ docker-escape-watch installed but self-test didn't log — check manually" >&2
  fi
  sudo docker rm -f escape-watch-selftest &>/dev/null || true
}

install_escape_watch

info "Done. This server is set up as a shared deploy machine."
info "Provision each deploy account: sudo ./oracle-vm-setup.sh <username> deploy"
info "See scripts/limited-deploy-user.md for the full access model."
