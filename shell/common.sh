# Shared interactive environment for bash and zsh.
# Sourced from shell/.zshrc and shell/.bashrc.

# Prepend a directory to PATH once. Later sources of this file do not duplicate it.
path_prepend() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1${PATH:+:$PATH}"; export PATH ;;
  esac
}

# bash only. zsh uniques PATH with `typeset -U path` (unquoted expansion does not split here).
path_dedupe() {
  local old="$PATH" entry new=""
  local IFS=:
  for entry in $old; do
    [ -n "$entry" ] || continue
    case ":$new:" in
      *":$entry:"*) ;;
      *) new="${new:+$new:}$entry" ;;
    esac
  done
  PATH="$new"
  export PATH
}

case "$(uname -s)" in
  Darwin) _OS="mac" ;;
  Linux)  _OS="linux" ;;
  *) _OS="unknown" ;;
esac
export _OS

if [ "$_OS" = "mac" ] && [ -d /opt/homebrew/bin ]; then
  path_prepend /opt/homebrew/sbin
  path_prepend /opt/homebrew/bin
  _BREW_PREFIX="/opt/homebrew"
elif [ "$_OS" = "linux" ] && [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  _BREW_PREFIX="/home/linuxbrew/.linuxbrew"
fi

path_prepend "$HOME/.local/bin"

if [ -d "$HOME/.bun" ]; then
  export BUN_INSTALL="$HOME/.bun"
  path_prepend "$BUN_INSTALL/bin"
fi

# Rustup. No-op until cargo is installed.
if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi

export CDPATH=".:$HOME/dev:$HOME/dev/github:/opt:/opt/stacks"

export CLAUDE_MODEL="${CLAUDE_MODEL:-claude-opus-4-6}"

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="
  --height 40% --layout=reverse --border
  --preview 'bat --color=always --style=numbers --line-range=:500 {}'
  --preview-window 'right:60%:wrap'
  --bind 'ctrl-/:toggle-preview'
"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
