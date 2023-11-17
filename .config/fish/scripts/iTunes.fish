#!/usr/bin/env fish
source $my_config

# domain defaults
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# application defaults
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowStatusBar -bool true
killall Finder
defaults write com.apple.dock workspaces-auto-swoosh -bool NO
killall Dock
defaults write com.apple.screencapture location $scr
killall SystemUIServer
