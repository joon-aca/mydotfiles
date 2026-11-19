# Bash mirror of .zshrc — used as a fallback when zsh isn't available.
# Aliases and functions are shared with zsh. zsh-only pieces stay out of this file.

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
# SHARE_HISTORY-ish. Don't stack another history -a if this file is sourced again.
case ";${PROMPT_COMMAND:-};" in
  *";history -a;"*) ;;
  *) PROMPT_COMMAND="history -a${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
esac

# Misc niceties
shopt -s checkwinsize
shopt -s cdspell 2>/dev/null
shopt -s autocd 2>/dev/null
set -o physical 2>/dev/null        # follow symlinks when cd-ing (zsh CHASE_LINKS)

#### SHARED ENVIRONMENT ####
_here="${BASH_SOURCE[0]}"
if [ -L "$_here" ]; then
  _here="$(readlink "$_here")"
fi
_SHELL_DIR="$(cd "$(dirname "$_here")" && pwd)"
unset _here
# shellcheck source=common.sh
. "$_SHELL_DIR/common.sh"
unset _SHELL_DIR

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
  # shellcheck source=/dev/null
  . ~/.fzf.bash
elif [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
  # shellcheck source=/dev/null
  . /usr/share/doc/fzf/examples/key-bindings.bash
  # shellcheck source=/dev/null
  [ -f /usr/share/doc/fzf/examples/completion.bash ] && . /usr/share/doc/fzf/examples/completion.bash
fi

#### COMPLETION ####
# bash-completion (Homebrew or apt)
if [ -n "${_BREW_PREFIX:-}" ] && [ -r "$_BREW_PREFIX/etc/profile.d/bash_completion.sh" ]; then
  # shellcheck source=/dev/null
  . "$_BREW_PREFIX/etc/profile.d/bash_completion.sh"
elif [ -r /etc/bash_completion ]; then
  # shellcheck source=/dev/null
  . /etc/bash_completion
fi

#### LOAD ALIASES & FUNCTIONS ####
# Shared with zsh — these files are bash-compatible.
# shellcheck source=/dev/null
[ -f ~/.zsh/aliases.zsh ]   && . ~/.zsh/aliases.zsh
# shellcheck source=/dev/null
[ -f ~/.zsh/functions.zsh ] && . ~/.zsh/functions.zsh

# This machine only.
# shellcheck source=/dev/null
[ -f "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"

path_dedupe
