
# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"



#### ZSH CORE SETTINGS ####

# Disable logoff with Control-D
set -o ignoreeof

# History behavior
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history

#### COMPLETION ####
autoload -Uz compinit
zmodload -F zsh/stat b:zstat
_compdump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ ! -s $_compdump ]]; then
  compinit
else
  # Rebuild the dump at most daily. compinit -C skips the security check.
  _comp_age=$(( EPOCHSECONDS - $(zstat +mtime "$_compdump") ))
  if (( _comp_age > 86400 )); then
    compinit
  else
    compinit -C
  fi
fi
unset _compdump _comp_age

# Autocomplete options - noautomenu matches tcsh behavior (no cycling menu)
setopt noautomenu

# Follow symlinks when cd-ing
setopt CHASE_LINKS

#### SHARED ENVIRONMENT ####
_here="${(%):-%N}"
[[ -L $_here ]] && _here="$(readlink "$_here")"
_SHELL_DIR="${_here:h}"
unset _here
source "$_SHELL_DIR/common.sh"
# First occurrence wins, so a second `source ~/.zshrc` does not grow PATH.
typeset -U path

#### MODERN CLI INTEGRATIONS ####

# zoxide - smarter cd
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# fzf - fuzzy finder
if [ -f ~/.fzf.zsh ]; then
  source ~/.fzf.zsh
elif [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
  [ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
fi

# fzf steals ctrl-t for file search, clobbering the standard emacs
# transpose-chars binding. Restore ctrl-t and move file search to ctrl-q,
# an obscure default (push-line) nobody uses.
if (( $+widgets[fzf-file-widget] )); then
  bindkey '^T' transpose-chars
  bindkey '^Q' fzf-file-widget
fi

# Starship prompt. Syntax highlighting is sourced later, and wants to stay near the end.
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

#### ZSH PLUGINS ####

# Autosuggestions — brew location or apt location
if [ -f "${_BREW_PREFIX:-}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$_BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
elif [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
bindkey '^[[Z' autosuggest-accept  # Shift+Tab to accept suggestion

#### KEYBINDINGS & COMPLETION ####

# List directory contents when hitting tab on blank line
tcsh_autolist() {
  if [[ -z ${LBUFFER// } ]]; then
    BUFFER="ls " CURSOR=3 zle list-choices
  else
    zle expand-or-complete-prefix
  fi
}
zle -N tcsh_autolist
bindkey '^I' tcsh_autolist

#### LOAD YOUR FILES ####
[ -f ~/.zsh/aliases.zsh ] && source ~/.zsh/aliases.zsh
[ -f ~/.zsh/functions.zsh ] && source ~/.zsh/functions.zsh
[ -f "$_SHELL_DIR/http.zsh" ] && source "$_SHELL_DIR/http.zsh"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# This machine only. OpenClaw, OpenCode, and anything an installer wants to append.
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# Syntax highlighting wants to be sourced after widgets and aliases.
if [ -f "${_BREW_PREFIX:-}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$_BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"

# OpenClaw Completion
[[ "$_OS" == "mac" ]] && source "/Users/joon/.openclaw/completions/openclaw.zsh"

# opencode
[[ "$_OS" == "mac" ]] && export PATH=/Users/joon/.opencode/bin:$PATH

typeset -U path
unset _SHELL_DIR
