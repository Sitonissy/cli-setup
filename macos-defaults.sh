#!/usr/bin/env bash

set -euo pipefail

osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

# iTerm2
if [ -d "/Applications/iTerm.app" ]; then
    defaults write com.googlecode.iterm2 "TerminalMargin" -int 15
    defaults write com.googlecode.iterm2 "TerminalVMargin" -int 15
fi

# Finder & Dock
defaults write com.apple.finder AppleShowAllFiles -bool true

defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.3

# Time Machine
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

killall Finder || true
killall Dock || true

