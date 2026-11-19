#### CORE ####
alias c='clear'
alias h='history'
alias q='exit'
alias claude6='claude --model claude-opus-4-6'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

#### MODERN CLI DEFAULTS ####
# Prefer eza/bat/rg when installed, but don’t break if missing.
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons'
  alias ll='eza -lah --git --group --icons'
  alias la='eza -a --icons'
  alias lt='eza --tree --level=2 --icons'
fi

if command -v bat >/dev/null 2>&1; then
  # -pp: plain output, no pager, so pipes and scripts behave like cat
  alias cat='bat -pp'
  alias less='bat --paging=always'
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

#### HTTP (curl aliases replacing httpie) ####
alias http-get='curl -s -H "Accept: application/json"'
alias http-post='curl -s -X POST -H "Content-Type: application/json" -d'
alias http-put='curl -s -X PUT -H "Content-Type: application/json" -d'
alias http-patch='curl -s -X PATCH -H "Content-Type: application/json" -d'
alias http-delete='curl -s -X DELETE -H "Accept: application/json"'
alias http-head='curl -sI'

#### GIT ####
# Short shortcuts only. The rest live in ~/.gitconfig (`git s`, `git l`, `git cm`, ...).
alias g='git'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'

#### PROJECT SHORTCUTS (kept from old) ####
alias dev='cd ~/dev'
alias aca='cd ~/dev/github/aca'

#### CROSS-PLATFORM UTILITIES ####

# path - Print PATH entries one per line
alias path='echo -e ${PATH//:/\\n}'

# week - Show current ISO week number
alias week='date +%V'

# reload - Restart the shell
alias reload="exec ${SHELL} -l"

# rehash - Re-source the current shell's rc
if [ -n "${ZSH_VERSION:-}" ]; then
  alias rehash='source ~/.zshrc'
else
  alias rehash='source ~/.bashrc'
fi

#### OS-SPECIFIC UTILITIES ####

if [[ "$_OS" == "mac" ]]; then
  # macOS-specific (adapted from mathiasbynens/dotfiles)
  alias afk="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"
  alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
  alias cleanup="find . -type f -name '*.DS_Store' -ls -delete"
  alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
  alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"
  alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
  alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"
  alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl"
  alias chromekill="ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"
elif [[ "$_OS" == "linux" ]]; then
  alias open='xdg-open'
  alias afk='loginctl lock-session'
  alias flushdns='sudo systemd-resolve --flush-caches'
fi
