#!/usr/bin/env bash
# oracle-vm-setup.sh
# Initial setup for Oracle VMs: fix hostname and add a user.
#
# Usage: sudo ./oracle-vm-setup.sh <username> [ssh-source-user] [github-username] [github-email]
#   username         - new user to create
#   ssh-source-user  - user whose authorized_keys to copy (default: ubuntu)
#   github-username  - git config user.name (optional)
#   github-email     - git config user.email (optional)
#
# Example: sudo ./oracle-vm-setup.sh joon
#          sudo ./oracle-vm-setup.sh joon ubuntu joon-aca joon@africacode.academy

set -euo pipefail

# ── Args ──────────────────────────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <username> [ssh-source-user]"
    exit 1
fi

NEW_USER="$1"
SSH_SOURCE="${2:-ubuntu}"
GITHUB_USER="${3:-}"
GITHUB_EMAIL="${4:-}"

# ── Hostname fix ──────────────────────────────────────────────────────────────
CURRENT_HOSTNAME="$(hostname)"
NEW_HOSTNAME="${CURRENT_HOSTNAME/_vnic/}"
NEW_HOSTNAME="${NEW_HOSTNAME/-vnic/}"

if [[ "$CURRENT_HOSTNAME" != "$NEW_HOSTNAME" ]]; then
    echo "[hostname] Changing '$CURRENT_HOSTNAME' -> '$NEW_HOSTNAME'"
    hostnamectl set-hostname "$NEW_HOSTNAME"
else
    echo "[hostname] No change needed ('$CURRENT_HOSTNAME')"
fi

# ── Create user ───────────────────────────────────────────────────────────────
ZSH_PATH="$(which zsh 2>/dev/null || echo /usr/bin/zsh)"

if id "$NEW_USER" &>/dev/null; then
    echo "[user] '$NEW_USER' already exists, skipping creation"
else
    echo "[user] Creating '$NEW_USER' with shell $ZSH_PATH"
    useradd -m -s "$ZSH_PATH" "$NEW_USER"
fi

# ── Passwordless sudo ─────────────────────────────────────────────────────────
SUDOERS_FILE="/etc/sudoers.d/$NEW_USER"
echo "[sudo] Writing $SUDOERS_FILE"
echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS_FILE"
chmod 440 "$SUDOERS_FILE"

# ── Docker group ──────────────────────────────────────────────────────────────
if getent group docker &>/dev/null; then
    echo "[docker] Adding '$NEW_USER' to docker group"
    usermod -aG docker "$NEW_USER"
else
    echo "[docker] Docker group not found, skipping"
fi

# ── Copy SSH authorized_keys ──────────────────────────────────────────────────
SSH_SOURCE_DIR="/home/$SSH_SOURCE/.ssh"
SSH_DEST_DIR="/home/$NEW_USER/.ssh"

if [[ -f "$SSH_SOURCE_DIR/authorized_keys" ]]; then
    echo "[ssh] Copying authorized_keys from '$SSH_SOURCE' to '$NEW_USER'"
    mkdir -p "$SSH_DEST_DIR"
    cp "$SSH_SOURCE_DIR/authorized_keys" "$SSH_DEST_DIR/authorized_keys"
    chown -R "$NEW_USER:$NEW_USER" "$SSH_DEST_DIR"
    chmod 700 "$SSH_DEST_DIR"
    chmod 600 "$SSH_DEST_DIR/authorized_keys"
else
    echo "[ssh] No authorized_keys found for '$SSH_SOURCE', skipping"
fi

# ── Git / GitHub config ───────────────────────────────────────────────────────
if [[ -n "$GITHUB_USER" || -n "$GITHUB_EMAIL" ]]; then
    echo "[git] Configuring git for '$NEW_USER'"
    GITCONFIG="/home/$NEW_USER/.gitconfig"
    sudo -u "$NEW_USER" git config --global user.name  "$GITHUB_USER"
    sudo -u "$NEW_USER" git config --global user.email "$GITHUB_EMAIL"
    chown "$NEW_USER:$NEW_USER" "$GITCONFIG"
    echo "[git] user.name=$GITHUB_USER  user.email=$GITHUB_EMAIL"
else
    echo "[git] No GitHub details provided, skipping"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "Done."
echo "  Hostname : $(hostname)"
echo "  User     : $(id "$NEW_USER")"
[[ -n "$GITHUB_USER" ]]  && echo "  Git name : $GITHUB_USER"
[[ -n "$GITHUB_EMAIL" ]] && echo "  Git email: $GITHUB_EMAIL"
