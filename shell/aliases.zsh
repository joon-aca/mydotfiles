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

#### MACOS-SPECIFIC UTILITIES ####
# Adapted from mathiasbynens/dotfiles
# These are macOS-specific commands that improve daily workflow

# cleanup - Recursively delete .DS_Store files
# Usage: cleanup
# Why useful: macOS creates .DS_Store files everywhere, clutters git repos
# Run this in a directory to clean up all .DS_Store files in subdirectories
alias cleanup="find . -type f -name '*.DS_Store' -ls -delete"

# show/hide - Toggle hidden files visibility in Finder
# Usage: show   (shows hidden files like .git, .env, etc.)
#        hide   (hides them again)
# Why useful: Quick toggle for seeing dotfiles in Finder GUI
alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

# hidedesktop/showdesktop - Toggle desktop icons visibility
# Usage: hidedesktop   (hides all icons on desktop)
#        showdesktop   (shows them again)
# Why useful: Clean up desktop for screenshots or presentations
alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"

# path - Print PATH entries one per line
# Usage: path
# Why useful: Much easier to read than echo $PATH (which shows colon-separated)
alias path='echo -e ${PATH//:/\\n}'

# week - Show current ISO week number
# Usage: week
# Why useful: Quick reference for weekly planning, sprints, etc.
alias week='date +%V'

# reload - Restart the shell
# Usage: reload
# Why useful: After editing .zshrc or other config, reload without closing terminal
alias reload="exec ${SHELL} -l"

# afk - Lock the screen immediately
# Usage: afk
# Why useful: Quick keyboard command to lock screen (away from keyboard)
alias afk="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"

# flushdns - Clear DNS cache
# Usage: flushdns
# Why useful: When DNS isn't resolving correctly or you need fresh lookups
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"

# emptytrash - Thoroughly empty the Trash
# Usage: emptytrash
# Why useful: Securely empties trash and clears system logs
# Warning: This is permanent deletion, use with caution
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl"

# chromekill - Kill all Chrome renderer processes
# Usage: chromekill
# Why useful: Chrome can leak memory in renderer processes, this frees it up
alias chromekill="ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"
