#!/usr/bin/env bash
# oracle-vm-setup.sh
# Initial setup for Oracle VMs: fix hostname and add a user.
#
# Usage: sudo ./oracle-vm-setup.sh <username> [role] [ssh-source-user] [github-username] [github-email]
#   username         - new user to create
#   role             - admin | deploy (default: admin)
#                       admin  = full passwordless sudo + docker group (you, other admins)
#                       deploy = docker + caddy group only, no full sudo, scoped Caddy
#                                reload/validate via sudoers. See ../scripts/limited-deploy-user.md
#                                for the full model. Only meaningful on a box that's already
#                                been through shared-deploy-server-setup.sh.
#   ssh-source-user  - user whose authorized_keys to copy (default: ubuntu). Ignored for
#                       role=deploy — a deploy account should get its own key, not an
#                       admin's; authorized_keys is created empty, add their key after.
#   github-username  - git config user.name (optional, admin role only)
#   github-email     - git config user.email (optional, admin role only)
#
# Example: sudo ./oracle-vm-setup.sh joon
#          sudo ./oracle-vm-setup.sh joon admin ubuntu joon-aca joon@africacode.academy
#          sudo ./oracle-vm-setup.sh dreu deploy

set -euo pipefail

# ── Args ──────────────────────────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <username> [role: admin|deploy] [ssh-source-user] [github-username] [github-email]"
    exit 1
fi

NEW_USER="$1"
ROLE="${2:-admin}"
SSH_SOURCE="${3:-ubuntu}"
GITHUB_USER="${4:-}"
GITHUB_EMAIL="${5:-}"

if [[ "$ROLE" != "admin" && "$ROLE" != "deploy" ]]; then
    echo "role must be 'admin' or 'deploy', got: $ROLE" >&2
    exit 1
fi

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

# ── Sudo ──────────────────────────────────────────────────────────────────────
SUDOERS_FILE="/etc/sudoers.d/$NEW_USER"

if [[ "$ROLE" == "admin" ]]; then
    echo "[sudo] role=admin — writing full NOPASSWD sudo to $SUDOERS_FILE"
    echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS_FILE"
    chmod 440 "$SUDOERS_FILE"
else
    echo "[sudo] role=deploy — no full sudo grant"
    if getent group caddy &>/dev/null; then
        echo "[sudo] Writing scoped Caddy reload/validate grant to $SUDOERS_FILE"
        echo "$NEW_USER ALL=(root) NOPASSWD: /usr/bin/caddy validate --config /etc/caddy/Caddyfile, /usr/bin/systemctl reload caddy, /usr/bin/systemctl restart caddy" > "$SUDOERS_FILE"
        chmod 440 "$SUDOERS_FILE"
        visudo -c -f "$SUDOERS_FILE"
    else
        echo "[sudo] caddy group not found, skipping scoped grant"
    fi
fi

# ── Docker group ──────────────────────────────────────────────────────────────
if getent group docker &>/dev/null; then
    echo "[docker] Adding '$NEW_USER' to docker group"
    usermod -aG docker "$NEW_USER"
else
    echo "[docker] Docker group not found, skipping"
fi

# ── Caddy group (deploy role only — admins get it implicitly via full sudo) ──
if [[ "$ROLE" == "deploy" ]] && getent group caddy &>/dev/null; then
    echo "[caddy] Adding '$NEW_USER' to caddy group"
    usermod -aG caddy "$NEW_USER"
fi

# ── SSH authorized_keys ────────────────────────────────────────────────────────
SSH_DEST_DIR="/home/$NEW_USER/.ssh"

if [[ "$ROLE" == "deploy" ]]; then
    echo "[ssh] role=deploy — creating empty authorized_keys, add their own key after this runs"
    mkdir -p "$SSH_DEST_DIR"
    touch "$SSH_DEST_DIR/authorized_keys"
    chown -R "$NEW_USER:$NEW_USER" "$SSH_DEST_DIR"
    chmod 700 "$SSH_DEST_DIR"
    chmod 600 "$SSH_DEST_DIR/authorized_keys"
else
    SSH_SOURCE_DIR="/home/$SSH_SOURCE/.ssh"
    if [[ -f "$SSH_SOURCE_DIR/authorized_keys" ]]; then
        echo "[ssh] Appending authorized_keys from '$SSH_SOURCE' to '$NEW_USER'"
        mkdir -p "$SSH_DEST_DIR"
        cat "$SSH_SOURCE_DIR/authorized_keys" >> "$SSH_DEST_DIR/authorized_keys"
        sort -u -o "$SSH_DEST_DIR/authorized_keys" "$SSH_DEST_DIR/authorized_keys"
        chown -R "$NEW_USER:$NEW_USER" "$SSH_DEST_DIR"
        chmod 700 "$SSH_DEST_DIR"
        chmod 600 "$SSH_DEST_DIR/authorized_keys"
    else
        echo "[ssh] No authorized_keys found for '$SSH_SOURCE', skipping"
    fi
fi

# ── Git / GitHub config (admin role only — deploy accounts don't need this) ──
if [[ "$ROLE" == "admin" && ( -n "$GITHUB_USER" || -n "$GITHUB_EMAIL" ) ]]; then
    echo "[git] Configuring git for '$NEW_USER'"
    ( cd "/home/$NEW_USER" && sudo -u "$NEW_USER" git config --global user.name  "$GITHUB_USER" )
    ( cd "/home/$NEW_USER" && sudo -u "$NEW_USER" git config --global user.email "$GITHUB_EMAIL" )
    echo "[git] user.name=$GITHUB_USER  user.email=$GITHUB_EMAIL"
fi

# ── GitHub SSH key (admin role only) ──────────────────────────────────────────
GH_KEY="$SSH_DEST_DIR/id_ed25519"

if [[ "$ROLE" == "admin" && -n "$GITHUB_EMAIL" && ! -f "$GH_KEY" ]]; then
    echo "[github] Generating ed25519 SSH key for '$NEW_USER'"
    mkdir -p "$SSH_DEST_DIR"
    sudo -u "$NEW_USER" ssh-keygen -t ed25519 -C "$GITHUB_EMAIL" -f "$GH_KEY" -N ""
    chown -R "$NEW_USER:$NEW_USER" "$SSH_DEST_DIR"
    chmod 700 "$SSH_DEST_DIR"
    chmod 600 "$GH_KEY"
    chmod 644 "$GH_KEY.pub"
elif [[ -f "$GH_KEY" ]]; then
    echo "[github] SSH key already exists, skipping"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "Done."
echo "  Hostname : $(hostname)"
echo "  Role     : $ROLE"
echo "  User     : $(id "$NEW_USER")"
[[ -n "$GITHUB_USER" ]]  && echo "  Git name : $GITHUB_USER"
[[ -n "$GITHUB_EMAIL" ]] && echo "  Git email: $GITHUB_EMAIL"
if [[ "$ROLE" == "deploy" ]]; then
    echo ""
    echo "Add their SSH public key: echo 'ssh-... comment' >> $SSH_DEST_DIR/authorized_keys"
    echo "Validate it first: ssh-keygen -lf <their key file>"
fi
if [[ -f "$GH_KEY.pub" ]]; then
    echo ""
    echo "Add this SSH public key to GitHub (https://github.com/settings/ssh/new):"
    cat "$GH_KEY.pub"
fi
