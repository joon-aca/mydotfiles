#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
OS="$(uname -s)"
ARCH="$(uname -m)"

info()  { printf "\033[1;34m▸ %s\033[0m\n" "$*"; }
warn()  { printf "\033[1;33m⚠ %s\033[0m\n" "$*"; }
error() { printf "\033[1;31m✗ %s\033[0m\n" "$*"; exit 1; }

# Helper: install binary from latest GitHub release tarball/zip
# Args: repo, url_pattern (grep -P), binary_name
install_github_bin() {
  local repo="$1" pattern="$2" cmd="$3"
  if command -v "$cmd" &>/dev/null; then return; fi
  info "Installing $cmd from $repo..."
  local url
  url=$(curl -sL "https://api.github.com/repos/$repo/releases/latest" \
    | grep -oP "\"browser_download_url\":\s*\"\\K[^\"]*${pattern}[^\"]*") || true
  if [ -z "$url" ]; then
    warn "Could not find release asset for $cmd — install manually"
    return
  fi
  local tmp
  tmp=$(mktemp -d)
  local archive="$tmp/archive"
  curl -sL "$url" -o "$archive"
  case "$url" in
    *.tar.gz|*.tgz) tar -xzf "$archive" -C "$tmp" ;;
    *.zip)          unzip -qo "$archive" -d "$tmp" ;;
    *.deb)          sudo dpkg -i "$archive"; rm -rf "$tmp"; return ;;
  esac
  # Find the binary and install to /usr/local/bin
  local bin
  bin=$(find "$tmp" -name "$cmd" -type f -perm -111 | head -1)
  if [ -z "$bin" ]; then
    bin=$(find "$tmp" -name "$cmd" -type f | head -1)
  fi
  if [ -n "$bin" ]; then
    sudo install -m 755 "$bin" /usr/local/bin/"$cmd"
  else
    warn "Could not find $cmd binary in archive — install manually"
  fi
  rm -rf "$tmp"
}

# ─── macOS ───────────────────────────────────────────
install_mac() {
  # Install Homebrew if missing
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  info "Installing packages via Homebrew..."
  brew bundle install --file="$DOTFILES/Brewfile"

  # fzf key bindings
  "$(brew --prefix)/opt/fzf/install" --all --no-bash --no-fish --no-update-rc

  # Git credential helper
  git config --global credential.helper osxkeychain
}

# ─── Linux ───────────────────────────────────────────
install_linux() {
  # Verify sudo access upfront so sub-scripts (starship, etc.) don't fail
  if ! sudo -n true 2>/dev/null; then
    info "This script needs sudo — authenticating now..."
    sudo -v
  fi

  info "Installing apt packages..."
  sudo apt-get update
  sudo apt-get install -y \
    zsh zsh-autosuggestions zsh-syntax-highlighting \
    bat ripgrep fd-find fzf \
    tmux emacs-nox btop htop \
    git gh neovim \
    jq yq tree watch pv nmap wget pipx \
    nodejs npm curl unzip

  # Symlink fd/bat naming quirks on Ubuntu
  mkdir -p "$HOME/.local/bin"
  [ ! -e "$HOME/.local/bin/bat" ] && ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"
  [ ! -e "$HOME/.local/bin/fd" ]  && ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"

  # ── Tools not in apt ──

  # starship — download to temp dir, then sudo copy to /usr/local/bin
  # (the official installer's sudo prompt fails in non-TTY environments)
  if ! command -v starship &>/dev/null; then
    info "Installing starship..."
    local tmpbin
    tmpbin=$(mktemp -d)
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$tmpbin"
    sudo install -m 755 "$tmpbin/starship" /usr/local/bin/starship
    rm -rf "$tmpbin"
  fi

  # eza (official apt repo)
  if ! command -v eza &>/dev/null; then
    info "Installing eza..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt-get update && sudo apt-get install -y eza
  fi

  # git-delta (no aarch64 .deb — use tarball)
  install_github_bin "dandavison/delta" "delta.*aarch64-unknown-linux-gnu\\.tar\\.gz" "delta"

  # dust
  install_github_bin "bootandy/dust" "dust.*aarch64-unknown-linux-gnu\\.tar\\.gz" "dust"

  # procs
  install_github_bin "dalance/procs" "procs.*aarch64-linux\\.zip" "procs"

  # zoxide
  if ! command -v zoxide &>/dev/null; then
    info "Installing zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
  fi

  # fnm (Fast Node Manager) — for per-project node version management
  if ! command -v fnm &>/dev/null; then
    info "Installing fnm..."
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell --install-dir "$HOME/.local/bin"
  fi


  # Git credential helper
  git config --global credential.helper store
}

# ─── Common installs (both platforms) ────────────────
install_common() {
  # Ensure ~/.local/bin is on PATH
  if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
  fi

  # AI CLI tools
  info "Installing AI CLI tools..."

  # Claude Code — native installer (no Node required)
  if ! command -v claude &>/dev/null; then
    curl -fsSL https://claude.ai/install.sh | bash
  fi
  sudo ln -sf "$HOME/.local/bin/claude" /usr/local/bin/claude

  # Codex & Gemini — require system Node
  if command -v npm &>/dev/null; then
    sudo npm install -g @openai/codex
    sudo npm install -g @google/gemini-cli
  fi
}

# ─── Home directory config setup ─────────────────────
setup_home() {
  # Symlink all configs
  info "Symlinking configs..."
  ln -sf "$DOTFILES/shell/.zshrc"           "$HOME/.zshrc"
  mkdir -p "$HOME/.zsh"
  ln -sf "$DOTFILES/shell/aliases.zsh"      "$HOME/.zsh/aliases.zsh"
  ln -sf "$DOTFILES/shell/functions.zsh"    "$HOME/.zsh/functions.zsh"
  ln -sf "$DOTFILES/git/.gitconfig"         "$HOME/.gitconfig"
  ln -sf "$DOTFILES/tmux/.tmux.conf"        "$HOME/.tmux.conf"
  ln -sf "$DOTFILES/emacs/.emacs"           "$HOME/.emacs"
  mkdir -p "$HOME/.config"
  ln -sf "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"
  mkdir -p "$HOME/.claude"
  ln -sf "$DOTFILES/CLAUDE.md"             "$HOME/.claude/CLAUDE.md"

  # Set zsh as default shell
  if [[ "$SHELL" != */zsh ]]; then
    info "Setting zsh as default shell..."
    sudo chsh -s "$(which zsh)" "$(whoami)"
  fi

  info "Done! Run 'exec zsh' or open a new terminal."
}

# ─── Main ────────────────────────────────────────────
setup_home

if [[ "${1:-}" != "--home-only" && "${1:-}" != "-h" ]]; then
  case "$OS" in
    Darwin) install_mac ;;
    Linux)  install_linux ;;
    *)      error "Unsupported OS: $OS" ;;
  esac
  install_common
fi
