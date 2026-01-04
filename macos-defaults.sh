#!/usr/bin/env bash

###############################################################################
# macOS System Preferences Configuration
###############################################################################
#
# This script configures macOS system settings to optimize for development work.
# Settings are curated from mathiasbynens/dotfiles with detailed explanations.
#
# USAGE:
#   chmod +x macos-defaults.sh
#   ./macos-defaults.sh
#
# SAFETY:
#   - You'll be prompted for sudo password
#   - System Preferences will be closed to prevent conflicts
#   - Some settings require logout/restart to take effect
#   - You can comment out any section you don't want
#
# TO REVERSE:
#   Most settings can be reversed by changing "true" to "false" or vice versa,
#   then running the script again. System defaults can also be reset via
#   System Preferences GUI.
#
###############################################################################

# Close any open System Preferences panes to prevent them from overriding settings
osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing sudo timestamp until script finishes
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

echo "Configuring macOS system preferences..."
echo "This may take a few minutes."
echo ""

###############################################################################
# General UI/UX
###############################################################################
echo "› Configuring general UI/UX settings..."

# Set computer name (you should customize this)
# Uncomment and set your preferred computer name:
# sudo scutil --set ComputerName "YourComputerName"
# sudo scutil --set HostName "YourComputerName"
# sudo scutil --set LocalHostName "YourComputerName"

# Disable the sound effects on boot
# Why: Annoying in offices, meetings, or public spaces
# sudo nvram SystemAudioVolume=" "  # (disabled: prefer boot chime)

# Expand save panel by default
# Why: Always shows the full file browser instead of compact view
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
# Why: Shows all printing options without clicking "Show Details"
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not to iCloud) by default
# Why: Prevents accidental iCloud saves for local files
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Automatically quit printer app once print jobs complete
# Why: Prevents printer app from staying open unnecessarily
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable the "Are you sure you want to open this application?" dialog
# Why: Reduces annoying prompts for downloaded apps (use with caution)
# defaults write com.apple.LaunchServices LSQuarantine -bool false

# Disable Resume system-wide
# Why: Apps won't reopen windows from last session (personal preference)
# defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false

# Reveal IP address, hostname, OS version, etc. when clicking the clock in login window
# Why: Useful for debugging network issues or identifying machines
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

###############################################################################
# Keyboard & Input
###############################################################################
echo "› Configuring keyboard and input settings..."

# Disable smart quotes
# Why: ESSENTIAL for coding - smart quotes break code
# defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false  # (disabled: keep macOS typing features for normal writing)

# Disable smart dashes
# Why: ESSENTIAL for coding - prevents -- from becoming em-dash
# defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false  # (disabled: keep macOS typing features for normal writing)

# Disable automatic capitalization
# Why: Annoying for developers, variable names, commands, etc.
# defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false  # (disabled: keep macOS typing features for normal writing)

# Disable automatic period substitution
# Why: Prevents double-space from becoming period (annoying in code)
# defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false  # (disabled: keep macOS typing features for normal writing)

# Disable auto-correct
# Why: Interferes with code, commands, and technical writing
# defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false  # (disabled: keep macOS typing features for normal writing)

# Set a blazingly fast keyboard repeat rate
# Why: Faster navigation with held keys (vim, cursor movement)
# Values: 1 = fastest, 2 = very fast (default is 6)
defaults write NSGlobalDomain KeyRepeat -int 1

# Set a short initial key repeat delay
# Why: Faster initial repeat when holding keys
# Values: 10 = very short (default is 68)
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# Enable full keyboard access for all controls
# Why: Tab through all UI elements (buttons, etc.) not just text fields
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Disable press-and-hold for keys in favor of key repeat
# Why: Enables key repeat instead of showing accent menu (better for vim/cursor movement)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

###############################################################################
# Trackpad & Mouse
###############################################################################
echo "› Configuring trackpad and mouse settings..."

# Enable tap to click for this user and for the login screen
# Why: Faster interaction than physical click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Increase mouse tracking speed
# Why: Faster cursor movement (adjust value to preference)
# Values: 0 to 3, higher = faster (default is 1)
defaults write NSGlobalDomain com.apple.mouse.scaling -float 1.0  # (set to neutral baseline)

###############################################################################
# Screen & Display
###############################################################################
echo "› Configuring screen and display settings..."

# Require password immediately after sleep or screen saver begins
# Why: Security - protect your data if you step away
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Save screenshots to ~/Screenshots instead of Desktop
# Why: Keeps Desktop clean, organizes screenshots in one place
mkdir -p "${HOME}/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Screenshots"

# Save screenshots in PNG format
# Why: PNG has better quality and transparency support than JPG
# Options: BMP, GIF, JPG, PDF, TIFF
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
# Why: Cleaner screenshots without drop shadow around windows
defaults write com.apple.screencapture disable-shadow -bool true

# Enable subpixel font rendering on non-Apple LCDs
# Why: Improves font clarity on external monitors
# Reference: https://github.com/kevinSuttle/macOS-Defaults/issues/17#issuecomment-266633501
# defaults write NSGlobalDomain AppleFontSmoothing -int 1  # (disabled: largely ignored on modern macOS, can worsen external displays)

# Enable HiDPI display modes (requires restart)
# Why: Enables more resolution options on external displays
sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true

###############################################################################
# Finder
###############################################################################
echo "› Configuring Finder settings..."

# Show hidden files by default
# Why: See dotfiles, .git directories, etc. without toggling
# defaults write com.apple.finder AppleShowAllFiles -bool true

# Show all filename extensions
# Why: Know exact file types, prevents hiding malicious extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show status bar
# Why: Shows item count, available space at bottom of Finder
defaults write com.apple.finder ShowStatusBar -bool true

# Show path bar
# Why: Shows full path at bottom of Finder windows
defaults write com.apple.finder ShowPathbar -bool true

# Display full POSIX path as Finder window title
# Why: Quickly see and copy full path of current folder
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Keep folders on top when sorting by name
# Why: Folders always appear before files in lists
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# When performing a search, search the current folder by default
# Why: More predictable search scope
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension
# Why: You know what you're doing as a developer
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Enable spring loading for directories
# Why: Drag files over folders to open them (like iOS)
defaults write NSGlobalDomain com.apple.springing.enabled -bool true

# Remove the spring loading delay for directories
# Why: Instant folder opening when dragging files
defaults write NSGlobalDomain com.apple.springing.delay -float 0

# Avoid creating .DS_Store files on network or USB volumes
# Why: Prevents littering shared drives with macOS metadata
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Disable disk image verification
# Why: Faster mounting of .dmg files (use cautiously)
# defaults write com.apple.frameworks.diskimages skip-verify -bool true
# defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
# defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

# Use list view in all Finder windows by default
# Why: More information density than icon view
# Four-letter codes for the view modes: icnv, clmv, glyv, Nlsv
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Disable the warning before emptying the Trash
# Why: Speeds up trash deletion (be careful!)
# defaults write com.apple.finder WarnOnEmptyTrash -bool false

# Show the ~/Library folder
# Why: Access app support files, preferences, caches
chflags nohidden ~/Library

# Show the /Volumes folder
# Why: Easier access to mounted drives
sudo chflags nohidden /Volumes

###############################################################################
# Dock & Dashboard
###############################################################################
echo "› Configuring Dock and Dashboard..."

# Set the icon size of Dock items
# Why: Customize dock size (values: pixels, e.g., 36, 48, 64)
defaults write com.apple.dock tilesize -int 48

# Enable magnification on hover
# Why: See app names and icons better when hovering
# defaults write com.apple.dock magnification -bool true  # (disabled: prefer no dock magnification)

# Set magnification size
# defaults write com.apple.dock largesize -int 64  # (disabled: only relevant if magnification is enabled)

# Minimize windows into their application's icon
# Why: Keeps dock cleaner, groups windows with their apps
# defaults write com.apple.dock minimize-to-application -bool true  # (disabled: prefer default minimize behavior)

# Show indicator lights for open applications
# Why: Quickly see which apps are running
defaults write com.apple.dock show-process-indicators -bool true

# Don't animate opening applications from the Dock
# Why: Faster app launching feel
defaults write com.apple.dock launchanim -bool false

# Speed up Mission Control animations
# Why: Faster workspace switching
defaults write com.apple.dock expose-animation-duration -float 0.1

# Don't automatically rearrange Spaces based on most recent use
# Why: Keep your workspace order consistent
defaults write com.apple.dock mru-spaces -bool false

# Automatically hide and show the Dock
# Why: Maximize screen space (personal preference)
# defaults write com.apple.dock autohide -bool true

# Remove the auto-hiding Dock delay
# Why: Instant dock appearance when moving cursor to edge
defaults write com.apple.dock autohide-delay -float 0

# Remove the animation when hiding/showing the Dock
# Why: Instant dock show/hide
defaults write com.apple.dock autohide-time-modifier -float 0

# Make Dock icons of hidden applications translucent
# Why: Visual indicator of hidden vs. visible apps
defaults write com.apple.dock showhidden -bool true

###############################################################################
# Safari & WebKit
###############################################################################
echo "› Configuring Safari settings..."

# Privacy: don't send search queries to Apple
# Why: Privacy protection
# defaults write com.apple.Safari UniversalSearchEnabled -bool false  # (disabled: keep Safari defaults)
# defaults write com.apple.Safari SuppressSearchSuggestions -bool true  # (disabled: keep Safari defaults)

# Enable the Develop menu and the Web Inspector
# Why: ESSENTIAL for web development
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# Enable "Do Not Track"
# Why: Privacy protection (though not all sites respect it)
defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true

# Update extensions automatically
# Why: Security and bug fixes
defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true

###############################################################################
# Terminal
###############################################################################
echo "› Configuring Terminal settings..."

# Only use UTF-8 in Terminal.app
# Why: Unicode support for international characters, emojis, etc.
defaults write com.apple.terminal StringEncodings -array 4

# Enable Secure Keyboard Entry in Terminal.app
# Why: Prevents other apps from detecting keystrokes (security)
# See: https://security.stackexchange.com/a/47786/8918
# defaults write com.apple.terminal SecureKeyboardEntry -bool true  # (disabled: can interfere with hotkeys/tools; macOS already restricts input monitoring)

###############################################################################
# Time Machine
###############################################################################
echo "› Configuring Time Machine..."

# Prevent Time Machine from prompting to use new hard drives as backup volume
# Why: Prevents annoying popup when connecting external drives
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

###############################################################################
# Activity Monitor
###############################################################################
echo "› Configuring Activity Monitor..."

# Show the main window when launching Activity Monitor
# Why: Immediate visibility of system resources
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Activity Monitor Dock icon
# Why: Quick glance at CPU load from dock
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
# Why: Complete visibility of running processes
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
# Why: Quickly identify resource hogs
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

###############################################################################
# Text Edit
###############################################################################
echo "› Configuring TextEdit..."

# Use plain text mode for new TextEdit documents
# Why: Better default for developers and note-taking
defaults write com.apple.TextEdit RichText -int 0

# Open and save files as UTF-8 in TextEdit
# Why: Unicode compatibility
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

###############################################################################
# Photos
###############################################################################
echo "› Configuring Photos..."

# Prevent Photos from opening automatically when devices are plugged in
# Why: Annoying if you just want to charge your phone
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

###############################################################################
# Google Chrome
###############################################################################
echo "› Configuring Chrome settings..."

# Disable the all too sensitive backswipe on trackpads
# Why: Prevents accidental back navigation
defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false

# Use the system-native print preview dialog
# Why: Consistency with other macOS apps
defaults write com.google.Chrome DisablePrintPreview -bool true

# Expand the print dialog by default
# Why: Shows all options immediately
defaults write com.google.Chrome PMPrintingExpandedStateForPrint2 -bool true

###############################################################################
# Finish
###############################################################################

echo ""
echo "Done! Some changes require logout/restart to take effect."
echo ""
echo "Would you like to restart now? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo shutdown -r now
fi
