# Bash mirror of .zshrc — used as a fallback when zsh isn't available.
# Aliases and functions are shared with zsh (they're bash-compatible).

# Only run interactive setup for interactive shells.
case $- in
  *i*) ;;
  *) return ;;
esac

#### CORE SETTINGS ####

# Don't exit shell on Ctrl-D
set -o ignoreeof

# History behavior (closest bash equivalents to the zsh setopts)
HISTCONTROL=ignoreboth:erasedups   # HIST_IGNORE_ALL_DUPS + reduce blanks
HISTSIZE=100000
HISTFILESIZE=100000
HISTFILE=~/.bash_history
shopt -s histappend                # INC_APPEND_HISTORY equivalent
PROMPT_COMMAND="history -a; ${PROMPT_COMMAND:-}"  # SHARE_HISTORY-ish

# Misc niceties
shopt -s checkwinsize
shopt -s cdspell 2>/dev/null
shopt -s autocd 2>/dev/null

#### OS DETECTION ####
case "$(uname -s)" in
  Darwin) _OS="mac" ;;
  Linux)  _OS="linux" ;;
esac
export _OS

#### PATH / CDPATH ####
if [ "$_OS" = "mac" ] && [ -d /opt/homebrew/bin ]; then
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
  _BREW_PREFIX="/opt/homebrew"
elif [ "$_OS" = "linux" ] && [ -d /home/linuxbrew/.linuxbrew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  _BREW_PREFIX="/home/linuxbrew/.linuxbrew"
fi

export CDPATH=".:$HOME/dev:$HOME/dev/github:/opt"
export PATH="$HOME/.local/bin:$PATH"

#### ENVIRONMENT / TOOLING ####

# fnm (fast node manager)
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env)"
fi

#### MODERN CLI INTEGRATIONS ####

# Starship prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

# zoxide
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
fi

# fzf
if [ -f ~/.fzf.bash ]; then
  . ~/.fzf.bash
elif [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
  . /usr/share/doc/fzf/examples/key-bindings.bash
  [ -f /usr/share/doc/fzf/examples/completion.bash ] && . /usr/share/doc/fzf/examples/completion.bash
fi

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="
  --height 40% --layout=reverse --border
  --preview 'bat --color=always --style=numbers --line-range=:500 {}'
  --preview-window 'right:60%:wrap'
  --bind 'ctrl-/:toggle-preview'
"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

#### COMPLETION ####
# bash-completion (Homebrew or apt)
if [ -n "${_BREW_PREFIX:-}" ] && [ -r "$_BREW_PREFIX/etc/profile.d/bash_completion.sh" ]; then
  . "$_BREW_PREFIX/etc/profile.d/bash_completion.sh"
elif [ -r /etc/bash_completion ]; then
  . /etc/bash_completion
fi

#### LOAD ALIASES & FUNCTIONS ####
# Shared with zsh — these files are bash-compatible.
[ -f ~/.zsh/aliases.zsh ]   && . ~/.zsh/aliases.zsh
[ -f ~/.zsh/functions.zsh ] && . ~/.zsh/functions.zsh

#### BUN ####
# ~/.bun/_bun is zsh-only — bash gets the binary on PATH but no completion.
export BUN_INSTALL="$HOME/.bun"
[ -d "$BUN_INSTALL/bin" ] && export PATH="$BUN_INSTALL/bin:$PATH"
