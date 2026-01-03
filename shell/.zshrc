#### ZSH CORE SETTINGS ####

# Disable logoff with Control-D
set -o ignoreeof

# Autocomplete options
setopt noautomenu
setopt nomenucomplete

# Better history behavior
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY


#### OH-MY-ZSH CONFIG ####

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="joon"
CASE_SENSITIVE="true"
DISABLE_AUTO_UPDATE="true"

# Plugins (add more as needed)
plugins=(git git-joon)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh


#### ENVIRONMENT / TOOLING ####

# Node Version Manager - load it properly
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Auto-use .nvmrc if present
autoload -U add-zsh-hook
load-nvmrc() {
  if [[ -f .nvmrc && -r .nvmrc ]]; then
    nvm use --silent 2>/dev/null
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# CDPATH - directories to search when using cd
export CDPATH=".:$HOME/dev/github"

#### OPTIONAL: ZSH PLUGINS ####

# Autosuggestions
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey '^[[Z' autosuggest-accept

# Syntax highlighting
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


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


#### ALIASES ####

# Directory stack
alias pd=dirs
alias po=popd
alias pop=popd
alias pp=pushd

# Utilities
alias c=clear
alias h=history
alias inet='ifconfig -a | grep inet'
alias grep='grep -n --color=auto'

# Git
alias gdst='git diff --stat --color=always | less -R -X'
alias gdst-c='git diff --cached --stat --color=always | less -R -X'

# Project shortcuts (customize as needed)
alias dev='cd ~/dev'
alias aca='cd ~/dev/github/aca'


#### FUNCTIONS ####

# Find file by name (shallow/deep)
f()  { find . -name "*$@*"; }
ff() { find . -type f -name "*$@*"; }

# Recursive grep: all files
gall() { grep -ir --include="*" -- "$@" .; }

# Source grep (C, C++, JS, Py)
glsrc() { grep -i --include="*.[ch]*" --include="*.js*" --include="*.py" -- "$@" *; }
gsrc()  { grep -ir --include="*.[ch]*" --include="*.js*" --include="*.py" -- "$@" .; }

# Python grep
glpy() { grep -i --include="*.py" -- "$@" *; }
gpy()  { grep -ir --include="*.py" -- "$@" .; }

# JavaScript grep
gljs() { grep -i --include="*.js*" -- "$@" *; }
gjs()  { grep -ir --include="*.js*" -- "$@" .; }
