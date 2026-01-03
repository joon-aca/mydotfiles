#### CORE ####
alias c='clear'
alias h='history'
alias q='exit'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

#### MODERN CLI DEFAULTS ####
# Prefer eza/bat/rg when installed, but don’t break if missing.
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons'
  alias ll='eza -lah --git --icons'
  alias la='eza -a --icons'
  alias lt='eza --tree --level=2 --icons'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
  alias less='bat --paging=always'
fi

if command -v rg >/dev/null 2>&1; then
  alias grep='rg'
fi

#### DIRECTORY STACK (kept from old) ####
alias pd='dirs'
alias pu='pushd'
alias po='popd'
alias pop='popd'
alias pp='pushd'

#### NETWORK / QUICK LOOK ####
alias inet='ifconfig -a | grep inet'
alias myip='curl -s ifconfig.me'
alias ports='lsof -i -P -n | grep LISTEN'

#### GIT (kept + normalized) ####
alias g='git'
alias gs='git status'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate -20'
alias ga='git add'
alias gaa='git add .'
alias gc='git commit'
alias gca='git commit --amend'
alias gp='git push'
alias gpl='git pull'
alias gb='git branch'
alias gco='git checkout'

# Your old “diff stat paged” helpers (kept)
alias gdst='git diff --stat --color=always | less -R -X'
alias gdst-c='git diff --cached --stat --color=always | less -R -X'

#### PROJECT SHORTCUTS (kept from old) ####
alias dev='cd ~/dev'
alias aca='cd ~/dev/github/aca'
