#!/usr/bin/env bash
set -euo pipefail

info()  { printf "\033[1;34m▸ %s\033[0m\n" "$*"; }
warn()  { printf "\033[1;33m⚠ %s\033[0m\n" "$*"; }
error() { printf "\033[1;31m✗ %s\033[0m\n" "$*"; exit 1; }

[[ "$(uname -s)" == "Linux" ]] || error "This script is Linux-only"

# Verify sudo access upfront
if ! sudo -n true 2>/dev/null; then
  info "This script needs sudo — authenticating now..."
  sudo -v
fi

# ─── Docker (official apt repo) ──────────────────────
install_docker() {
  if command -v docker &>/dev/null; then
    info "Docker already installed: $(docker --version)"
    return
  fi

  info "Installing Docker via official apt repo..."
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg

  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  sudo usermod -aG docker "$USER"
  info "Docker installed. You may need to log out and back in for group membership to take effect."
}

# ─── Caddy (official apt repo) ───────────────────────
install_caddy() {
  if command -v caddy &>/dev/null; then
    info "Caddy already installed: $(caddy version)"
    return
  fi

  info "Installing Caddy via official apt repo..."
  sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl

  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list

  sudo apt-get update
  sudo apt-get install -y caddy
}

# ─── /opt/stacks (shared docker compose directory) ───
setup_stacks() {
  info "Setting up /opt/stacks..."
  sudo mkdir -p /opt/stacks
  sudo chgrp docker /opt/stacks
  sudo chmod 2775 /opt/stacks
}

# ─── Dockge (docker compose manager) ─────────────────
install_dockge() {
  if [[ -f /opt/dockge/compose.yaml ]]; then
    info "Dockge compose.yaml already exists"
  else
    info "Downloading Dockge compose.yaml..."
    sudo mkdir -p /opt/dockge
    sudo curl -fsSL https://raw.githubusercontent.com/louislam/dockge/master/compose.yaml -o /opt/dockge/compose.yaml
  fi

  info "Starting Dockge..."
  sudo docker compose -f /opt/dockge/compose.yaml up -d
}

# ─── Main ────────────────────────────────────────────
install_docker
install_caddy
setup_stacks
install_dockge

info "Done! Docker, Caddy, and Dockge are installed."
info "Verify with: docker --version, caddy version, curl localhost:5001"
