#!/usr/bin/env bash
# macOS defaults that still apply on macOS 27.
#
# Bootstrap does not run this. Apply it yourself:
#   ./macos-defaults.sh
#
# Key repeat and network .DS_Store need a logout. Finder and Dock are
# restarted at the end. Nothing here needs sudo.
set -euo pipefail

osascript -e 'tell application "System Settings" to quit' >/dev/null 2>&1 || true

echo "Applying macOS defaults..."

###############################################################################
# Keyboard
###############################################################################

# Hold a key to repeat it, instead of the accent popup.
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Faster than the Keyboard slider allows (slider floor is about 2 and 15).
# Needs a logout. 1 is fast enough to insert accidental repeats.
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# System Settings → Keyboard → Keyboard navigation. 0 is off, 2 is on.
defaults write NSGlobalDomain AppleKeyboardUIMode -int 2

###############################################################################
# Finder
###############################################################################

# Finder → Settings → Advanced → When performing a search: current folder.
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# No checkbox for this. The title bar shows the full path.
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Go → Library while holding Option does this for one session. chflags sticks.
chflags nohidden ~/Library

# Drag a file onto a folder and it opens immediately.
defaults write NSGlobalDomain com.apple.springing.enabled -bool true
defaults write NSGlobalDomain com.apple.springing.delay -float 0

###############################################################################
# Screenshots, lock screen, network volumes
###############################################################################

mkdir -p "${HOME}/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Screenshots"

# Require the password immediately after sleep or the screensaver.
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Apple-documented. Needs a logout. The USB twin of this key is unreliable.
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

###############################################################################
# Spaces, TextEdit, Time Machine
###############################################################################

# Desktop & Dock → Automatically rearrange Spaces based on most recent use.
defaults write com.apple.dock mru-spaces -bool false

defaults write com.apple.TextEdit RichText -int 0

defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

###############################################################################
# Apply
###############################################################################

killall Finder
killall Dock

echo ""
echo "Finder and Dock restarted."
echo "Log out so key repeat and network .DS_Store take effect."
