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

# ─── Swap file ───────────────────────────────────────
setup_swap() {
  local size="${1:-2G}"
  local swapfile="/swapfile"

  if swapon --show | grep -q "^${swapfile}"; then
    info "Swap already active: $(free -h | awk '/^Swap:/ {print $2}')"
    return
  fi

  info "Creating ${size} swap file at ${swapfile}..."
  sudo fallocate -l "$size" "$swapfile"
  sudo chmod 600 "$swapfile"
  sudo mkswap "$swapfile"
  sudo swapon "$swapfile"

  if ! grep -q "^${swapfile}" /etc/fstab; then
    echo "${swapfile} none swap sw 0 0" | sudo tee -a /etc/fstab > /dev/null
    info "Added swap to /etc/fstab for persistence across reboots"
  fi

  info "Swap enabled: $(free -h | awk '/^Swap:/ {print $2}')"
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

# ─── Node.js 22 LTS (NodeSource) ─────────────────────
install_node() {
  if node --version 2>/dev/null | grep -q '^v22\.'; then
    info "Node.js 22 already installed: $(node --version)"
    return
  fi

  info "Installing Node.js 22 LTS via NodeSource..."
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt-get install -y nodejs
  info "Node.js installed: $(node --version)"
}

# ─── fnm (Fast Node Manager) ─────────────────────────
install_fnm() {
  if command -v fnm &>/dev/null; then
    info "fnm already installed: $(fnm --version)"
    return
  fi

  info "Installing fnm..."
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell --install-dir "$HOME/.local/bin"
}

# ─── Main ────────────────────────────────────────────
setup_swap
install_docker
install_caddy
setup_stacks
install_dockge
install_node
install_fnm

info "Done! Swap, Docker, Caddy, Dockge, Node.js 22, and fnm are installed."
info "Verify with: docker --version, caddy version, curl localhost:5001, node --version"
