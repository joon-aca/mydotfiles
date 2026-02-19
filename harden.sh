#!/usr/bin/env bash
###############################################################################
# harden.sh — Prime & harden a fresh OCI Ubuntu 24.04 server
#
# Run as: ubuntu (the default OCI user, over SSH)
# Usage:  ./harden.sh [-u admin_user] [-h hostname]
#
# What it does:
#   1. Patches system, installs baseline packages
#   2. Hardens SSH (key-only, no root, rate-limited, port 22)
#   3. Configures fail2ban (SSH jail with escalating bans)
#   4. Sets up UFW firewall (deny all incoming, allow SSH)
#   5. Enables unattended security upgrades (auto-reboot at 4am)
#   6. Creates a key-only admin user (copies SSH keys from current user)
#   7. Optionally sets hostname
#
# What it does NOT do:
#   - Install dev tools (that's bootstrap.sh)
#
# Idempotent: safe to re-run. Config files are written fresh each time.
###############################################################################
set -euo pipefail

# ─── Defaults ────────────────────────────────────────
ADMIN_USER="joon"
SET_HOSTNAME=""
SSH_PORT="22"

# ─── Parse flags ─────────────────────────────────────
while getopts "u:h:p:" opt; do
  case "$opt" in
    u) ADMIN_USER="$OPTARG" ;;
    h) SET_HOSTNAME="$OPTARG" ;;
    p)
      if [ "$OPTARG" != "22" ]; then
        error "Custom SSH ports are disabled in this script revision. Keep SSH on port 22."
      fi
      SSH_PORT="22"
      ;;
    *) echo "Usage: $0 [-u admin_user] [-h hostname] [-p ssh_port]"; exit 1 ;;
  esac
done

info()  { printf "\033[1;34m▸ %s\033[0m\n" "$*"; }
warn()  { printf "\033[1;33m⚠ %s\033[0m\n" "$*"; }
error() { printf "\033[1;31m✗ %s\033[0m\n" "$*"; exit 1; }

# ─── Pre-flight ──────────────────────────────────────
if ! sudo -n true 2>/dev/null; then
  info "This script needs sudo — authenticating now..."
  sudo -v
fi

# Require at least one SSH key before enforcing key-only auth.
if [ ! -s "$HOME/.ssh/authorized_keys" ]; then
  error "Missing $HOME/.ssh/authorized_keys. Refusing to enforce key-only SSH without a key."
fi

# ─── 0) Hostname (optional) ─────────────────────────
if [ -n "$SET_HOSTNAME" ]; then
  info "Setting hostname to $SET_HOSTNAME..."
  sudo hostnamectl set-hostname "$SET_HOSTNAME"
fi

# ─── 1) Patch system ────────────────────────────────
info "Updating and upgrading system..."
sudo apt-get update
sudo apt-get -y full-upgrade
sudo apt-get -y autoremove --purge
sudo apt-get -y autoclean

# ─── 2) Baseline packages ───────────────────────────
info "Installing baseline packages..."
sudo apt-get install -y \
  ca-certificates curl wget gnupg lsb-release \
  git jq unzip \
  htop iotop nload \
  iproute2 net-tools tcpdump \
  dnsutils \
  ufw fail2ban \
  unattended-upgrades apt-listchanges

# ─── 3) Reboot check ────────────────────────────────
if [ -f /var/run/reboot-required ]; then
  warn "Kernel upgrade requires a reboot."
  warn "Rebooting now — re-run this script after reboot to continue."
  sudo reboot
  exit 0
fi

# ─── 4) SSH hardening ───────────────────────────────
info "Writing SSH hardening config..."
sudo tee /etc/ssh/sshd_config.d/99-hardening.conf > /dev/null <<EOF
# Managed by harden.sh — do not edit manually
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
AuthenticationMethods publickey
UsePAM yes

# Rate limiting
MaxAuthTries 3
LoginGraceTime 30
MaxSessions 10
MaxStartups 10:30:60

# Timeouts — drop idle connections after 10 min
ClientAliveInterval 300
ClientAliveCountMax 2

# Disable unnecessary features
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitTunnel no
PermitUserEnvironment no

# Logging
LogLevel VERBOSE
EOF

# Validate config before reloading
if sudo sshd -t 2>&1; then
  info "SSH config valid — reloading SSH service..."
  if sudo systemctl list-unit-files | grep -q '^ssh\.service'; then
    sudo systemctl reload ssh
  elif sudo systemctl list-unit-files | grep -q '^sshd\.service'; then
    sudo systemctl reload sshd
  else
    error "Could not find ssh.service or sshd.service to reload."
  fi
else
  error "SSH config validation failed — NOT reloading. Fix /etc/ssh/sshd_config.d/99-hardening.conf"
fi

# ─── 5) fail2ban ────────────────────────────────────
info "Configuring fail2ban..."

# Global defaults
sudo tee /etc/fail2ban/jail.d/defaults-debian.conf > /dev/null <<EOF
# Managed by harden.sh
[DEFAULT]
# Use nftables (Ubuntu 24.04 default)
banaction = nftables
banaction_allports = nftables[type=allports]
backend = systemd

# Escalating bans: repeat offenders get longer bans
bantime.increment = true
bantime.factor = 1
bantime.maxtime = 1w
EOF

# SSH jail — aggressive but fair
sudo tee /etc/fail2ban/jail.d/sshd.local > /dev/null <<EOF
# Managed by harden.sh
[sshd]
enabled = true
port = ${SSH_PORT}
filter = sshd
logpath = /var/log/auth.log
backend = systemd

# 3 failures in 10 minutes = 1 hour ban (escalates on repeat)
maxretry = 3
findtime = 10m
bantime = 1h
EOF

# Restart fail2ban to pick up changes
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban
info "fail2ban status:"
sudo fail2ban-client status sshd 2>/dev/null || warn "fail2ban sshd jail not ready yet"

# ─── 6) UFW firewall ────────────────────────────────
info "Configuring UFW firewall..."

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow and rate limit SSH on port 22
sudo ufw allow OpenSSH
sudo ufw limit OpenSSH

# Enable
sudo ufw --force enable
info "UFW status:"
sudo ufw status verbose

# ─── 7) Unattended security upgrades ────────────────
info "Configuring unattended upgrades..."

# Override config: enable security updates, auto-reboot at 4am, cleanup
sudo tee /etc/apt/apt.conf.d/51unattended-upgrades-harden > /dev/null <<'EOF'
// Managed by harden.sh — overrides for 50unattended-upgrades

// Auto-remove unused kernels and dependencies after upgrade
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Auto-reboot if needed (kernel updates), at a safe time
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-WithUsers "true";
Unattended-Upgrade::Automatic-Reboot-Time "04:00";

// Log to syslog for auditability
Unattended-Upgrade::SyslogEnable "true";
Unattended-Upgrade::SyslogFacility "daemon";
EOF

# Ensure the auto-upgrades timer is enabled
sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
EOF

sudo systemctl enable unattended-upgrades
sudo systemctl restart unattended-upgrades
info "Unattended upgrades enabled (auto-reboot at 04:00 if needed)"

# ─── 8) Create admin user (key-only) ────────────────
info "Setting up admin user: $ADMIN_USER"

if id "$ADMIN_USER" >/dev/null 2>&1; then
  info "User $ADMIN_USER already exists — skipping create"
else
  sudo useradd -m -s /bin/bash "$ADMIN_USER"
fi

# Add to sudo group
sudo usermod -aG sudo "$ADMIN_USER"

# Lock password (key-only; SSH password auth is off)
sudo passwd -l "$ADMIN_USER" 2>/dev/null || true

# Merge authorized_keys from current user -> admin user (append unique keys)
info "Merging SSH authorized_keys into $ADMIN_USER..."
sudo install -d -m 700 -o "$ADMIN_USER" -g "$ADMIN_USER" /home/"$ADMIN_USER"/.ssh
sudo touch /home/"$ADMIN_USER"/.ssh/authorized_keys
sudo chown "$ADMIN_USER":"$ADMIN_USER" /home/"$ADMIN_USER"/.ssh/authorized_keys
sudo chmod 600 /home/"$ADMIN_USER"/.ssh/authorized_keys
sudo sh -c "cat /home/${ADMIN_USER}/.ssh/authorized_keys \"$HOME/.ssh/authorized_keys\" | awk 'NF && !seen[\$0]++' > /home/${ADMIN_USER}/.ssh/authorized_keys.new"
sudo mv /home/"$ADMIN_USER"/.ssh/authorized_keys.new /home/"$ADMIN_USER"/.ssh/authorized_keys
sudo chown "$ADMIN_USER":"$ADMIN_USER" /home/"$ADMIN_USER"/.ssh/authorized_keys
sudo chmod 600 /home/"$ADMIN_USER"/.ssh/authorized_keys

if ! sudo test -s /home/"$ADMIN_USER"/.ssh/authorized_keys; then
  error "Target user $ADMIN_USER has no authorized_keys after setup; aborting to prevent lockout."
fi

# Verify
info "Verifying $ADMIN_USER:"
id "$ADMIN_USER"

# ─── 9) SSH verification gate ───────────────────────
LOCAL_IP=$(hostname -I | awk '{print $1}')
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  STOP — verify SSH before closing this session      ║"
echo "║                                                     ║"
echo "║  Open a SECOND terminal and run:                    ║"
printf "║    ssh %s@%-36s  ║\n" "$ADMIN_USER" "$LOCAL_IP"
echo "║    sudo whoami                                      ║"
echo "║                                                     ║"
echo "║  If that works, come back here and press Enter.     ║"
echo "║  If not, Ctrl-C now and debug.                      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
read -r -p "Press Enter to continue (or Ctrl-C to abort)..."

# ─── 10) Final audit ────────────────────────────────
echo ""
info "=== Hardening Summary ==="
echo ""
info "SSH:"
grep -v '^#' /etc/ssh/sshd_config.d/99-hardening.conf | grep -v '^$' | sed 's/^/    /'
echo ""
info "fail2ban (sshd jail):"
sudo fail2ban-client status sshd 2>/dev/null | sed 's/^/    /' || true
echo ""
info "UFW:"
sudo ufw status numbered 2>/dev/null | sed 's/^/    /'
echo ""
info "Unattended upgrades: enabled (security, auto-reboot at 04:00)"
info "Listening ports:"
sudo ss -tlnp 2>/dev/null | sed 's/^/    /'
echo ""
info "Hardening complete."
info "Next steps:"
info "  1. SSH in as $ADMIN_USER"
info "  2. Clone dotfiles and run bootstrap.sh"
info "     git clone git@github.com:joon-aca/mydotfiles.git ~/mydotfiles"
info "     cd ~/mydotfiles && ./bootstrap.sh"
