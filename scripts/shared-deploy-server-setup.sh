#!/usr/bin/env bash
# shared-deploy-server-setup.sh
#
# Turns a server that already has baseline infra (../server-setup.sh —
# Docker, Caddy, /opt/stacks, Dockge) into a shared multi-user deploy
# machine: installs the docker-escape-watch backstop and the /opt/stacks
# README aimed at deploy accounts.
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
# Always re-syncs the script/unit from the repo and restarts, even if the
# service is already running — otherwise re-running this after updating
# docker-escape-watch.sh silently keeps serving the stale version.
install_escape_watch() {
  local changed=""

  if ! sudo cmp -s "$SCRIPT_DIR/docker-escape-watch.sh" /usr/local/sbin/docker-escape-watch 2>/dev/null; then
    changed=1
  fi
  if ! sudo cmp -s "$SCRIPT_DIR/docker-escape-watch.service" /etc/systemd/system/docker-escape-watch.service 2>/dev/null; then
    changed=1
  fi

  if [[ -z "$changed" ]] && systemctl is-active --quiet docker-escape-watch 2>/dev/null; then
    info "docker-escape-watch already up to date and running"
    return
  fi

  info "Installing/updating docker-escape-watch..."
  sudo cp "$SCRIPT_DIR/docker-escape-watch.sh" /usr/local/sbin/docker-escape-watch
  sudo chown root:root /usr/local/sbin/docker-escape-watch
  sudo chmod 755 /usr/local/sbin/docker-escape-watch

  sudo cp "$SCRIPT_DIR/docker-escape-watch.service" /etc/systemd/system/docker-escape-watch.service
  sudo systemctl daemon-reload
  sudo systemctl enable --now docker-escape-watch
  sudo systemctl restart docker-escape-watch

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

# ─── /opt/stacks README (deployer-facing docs) ───────
install_stacks_readme() {
  [[ -d /opt/stacks ]] || error "/opt/stacks not found — run server-setup.sh first"

  info "Installing /opt/stacks/README.md..."
  sudo cp "$SCRIPT_DIR/stacks-README.md" /opt/stacks/README.md
  sudo chown root:docker /opt/stacks/README.md
  sudo chmod 664 /opt/stacks/README.md
}

# ─── User-class groups and sudoers rules ─────────────
# Two classes, two groups, two files. Membership is the grant, so promoting or
# demoting is a group change rather than hunting per-user files in sudoers.d.
#
# Numbered so 30-sysadmin sorts after 20-deploy: sudoers.d is read lexically
# and the last match wins, so anyone in both groups keeps full root instead of
# being silently restricted by the deploy rules.
#
# The deploy rules are a DENY-list. Every unit is permitted except the
# protected ones, so a new project needs no edit here. An allow-list would
# need one per project, and the obvious shorthand is unsafe: sudoers matches
# arguments as one concatenated string, so `systemctl stop sammy-*` also
# matches `stop sammy-foo docker`. See sudoers(5), "Wildcards".
install_user_classes() {
  info "Creating sysadmin and deploy groups..."
  sudo groupadd -f sysadmin
  sudo groupadd -f deploy

  local tmp
  tmp=$(mktemp)

  cat > "$tmp" <<'EOF'
# Managed by mydotfiles/scripts/shared-deploy-server-setup.sh — edit there.
#
# Deploy class: systemctl on any unit except PROTECTED. Deny-list so new
# projects need no change. NOT a security boundary — deploy users are in
# `docker`, which is root-equivalent by construction. This prevents
# accidents; docker-escape-watch is the detection backstop.

Cmnd_Alias SYSTEMCTL_MANAGE = \
    /usr/bin/systemctl start *, \
    /usr/bin/systemctl stop *, \
    /usr/bin/systemctl restart *, \
    /usr/bin/systemctl reload *, \
    /usr/bin/systemctl reload-or-restart *, \
    /usr/bin/systemctl enable *, \
    /usr/bin/systemctl disable *, \
    /usr/bin/systemctl daemon-reload

Cmnd_Alias SYSTEMCTL_READ = \
    /usr/bin/systemctl status *, \
    /usr/bin/systemctl is-active *, \
    /usr/bin/systemctl is-enabled *, \
    /usr/bin/systemctl is-failed *, \
    /usr/bin/systemctl show *, \
    /usr/bin/systemctl cat *, \
    /usr/bin/systemctl list-units *, \
    /usr/bin/systemctl list-unit-files *, \
    /usr/bin/journalctl -u *

# Infrastructure a deploy user must not restart while meaning to restart
# their own service. Trailing glob catches .service / .socket forms.
Cmnd_Alias PROTECTED = \
    /usr/bin/systemctl * docker*, \
    /usr/bin/systemctl * containerd*, \
    /usr/bin/systemctl * ssh*, \
    /usr/bin/systemctl * fail2ban*, \
    /usr/bin/systemctl * docker-escape-watch*, \
    /usr/bin/systemctl * systemd-*, \
    /usr/bin/systemctl * polkit*, \
    /usr/bin/systemctl * cloudflared*, \
    /usr/bin/systemctl * multipathd*, \
    /usr/bin/systemctl * iscsid*, \
    /usr/bin/systemctl * oracle-cloud-agent*, \
    /usr/bin/systemctl * snap.*

# edit/link load an arbitrary unit file and run it as root. A deploy user
# reaching for these is always a mistake; unit files are a sysadmin task.
Cmnd_Alias FOOTGUNS = \
    /usr/bin/systemctl edit *, \
    /usr/bin/systemctl link *, \
    /usr/bin/systemctl mask *, \
    /usr/bin/systemctl set-property *

%deploy ALL=(root) NOPASSWD: SYSTEMCTL_MANAGE, SYSTEMCTL_READ, !PROTECTED, !FOOTGUNS
%deploy ALL=(root) NOPASSWD: /usr/bin/caddy validate --config /etc/caddy/Caddyfile
EOF

  # Validate before installing — a malformed file in sudoers.d breaks sudo for
  # everyone, including whoever is trying to fix it.
  sudo visudo -cqf "$tmp" || { rm -f "$tmp"; error "generated 20-deploy failed validation"; }
  sudo install -o root -g root -m 0440 "$tmp" /etc/sudoers.d/20-deploy

  cat > "$tmp" <<'EOF'
# Managed by mydotfiles/scripts/shared-deploy-server-setup.sh — edit there.
#
# Sysadmin class: full root. Sorts after 20-deploy so a user in both groups
# resolves to full root (sudoers: last match wins).

%sysadmin ALL=(ALL) NOPASSWD:ALL
EOF

  sudo visudo -cqf "$tmp" || { rm -f "$tmp"; error "generated 30-sysadmin failed validation"; }
  sudo install -o root -g root -m 0440 "$tmp" /etc/sudoers.d/30-sysadmin
  rm -f "$tmp"

  sudo visudo -c >/dev/null || error "sudoers validation failed after install"
  info "Installed /etc/sudoers.d/20-deploy and 30-sysadmin"
}

install_escape_watch
install_stacks_readme
install_user_classes

info "Done. This server is set up as a shared deploy machine."
info "Provision each account: sudo ./oracle-vm-setup.sh <username> {admin|deploy}"
info "See scripts/limited-deploy-user.md for the full access model."
info ""
info "Migrating an existing server? Per-user files in /etc/sudoers.d/ are now"
info "superseded. Verify with 'sudo -l -U <user>' BEFORE removing any."
