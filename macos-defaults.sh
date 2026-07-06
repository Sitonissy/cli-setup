#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Applying macOS UI defaults..."

# 1. iTerm2 Margins (Internal padding)
# Sets left/right and top/bottom margins for a cleaner, premium look
defaults write com.googlecode.iterm2 "TerminalMargin" -int 15
defaults write com.googlecode.iterm2 "TerminalVMargin" -int 15

# 2. Finder and Dock Minimalist Tweaks
# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles -bool true

# Auto-hide Dock without delay
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.3

# 3. Menu Bar (Clean up some clutter if possible via defaults)
# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Restart affected system applications
killall Finder
killall Dock

echo "macOS defaults successfully applied."
