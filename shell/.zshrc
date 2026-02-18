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
compinit

# Autocomplete options (kept from old - prevents aggressive tab completion)
setopt noautomenu
setopt nomenucomplete

#### OS DETECTION ####
case "$(uname -s)" in
  Darwin) _OS="mac" ;;
  Linux)  _OS="linux" ;;
esac

#### PATH / CDPATH ####
if [[ "$_OS" == "mac" ]]; then
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
  _BREW_PREFIX="/opt/homebrew"
elif [[ "$_OS" == "linux" && -d /home/linuxbrew/.linuxbrew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  _BREW_PREFIX="/home/linuxbrew/.linuxbrew"
fi

# CDPATH - directories to search when using cd
export CDPATH=".:$HOME/dev/github"

# User binaries
export PATH="$HOME/.local/bin:$PATH"

#### ENVIRONMENT / TOOLING ####

# Node Version Manager (fnm - fast alternative to nvm)
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd)"
fi

# NVM (uncomment if you prefer nvm over fnm)
# export NVM_DIR="$HOME/.nvm"
# [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
# [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
#
# # Auto-use .nvmrc if present
# autoload -U add-zsh-hook
# load-nvmrc() {
#   if [[ -f .nvmrc && -r .nvmrc ]]; then
#     nvm use --silent 2>/dev/null
#   fi
# }
# add-zsh-hook chpwd load-nvmrc
# load-nvmrc

#### MODERN CLI INTEGRATIONS ####

# Starship prompt - must be at the end of the file
eval "$(starship init zsh)"

# zoxide - smarter cd
eval "$(zoxide init zsh)"

# fzf - fuzzy finder
if [ -f ~/.fzf.zsh ]; then
  source ~/.fzf.zsh
elif [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
  [ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
fi

# fzf default options
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="
  --height 40% --layout=reverse --border
  --preview 'bat --color=always --style=numbers --line-range=:500 {}'
  --preview-window 'right:60%:wrap'
  --bind 'ctrl-/:toggle-preview'
"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

#### ZSH PLUGINS ####

# Autosuggestions — brew location or apt location
if [ -f "${_BREW_PREFIX:-}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$_BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
elif [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
bindkey '^[[Z' autosuggest-accept  # Shift+Tab to accept suggestion

# Syntax highlighting — brew location or apt location (must be near the end)
if [ -f "${_BREW_PREFIX:-}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$_BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

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
