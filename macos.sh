#!/usr/bin/env zsh

# macos.sh
# Set some better defaults

# This script uses `dialog`, so check its installed
if ! (( $+commands[dialog] ))
then
    echo "dialog command not installed"
    exit 1
fi

# Ask for the admin password upfront
sudo -v

# Keep the sudo session alive
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

BACKTITLE="macOS Setup"

# Duplicate (make a backup copy of) file descriptor 1 
# on descriptor 3
exec 3>&1

CHOICES=$(dialog --backtitle $BACKTITLE \
  --clear \
  --checklist "Which settings would you like to change?" 20 80 10 \
  "1" "Expand save panel by default" "OFF" \
  "2" "Expand print panel by default" "OFF" \
  "3" "Automatically quit Printer app after job has finished" "OFF" \
  "4" "Check for software updates daily" "OFF" \
  "5" "Save screenshots in PNG format" "OFF" \
  "6" "Show all file extensions in Finder" "OFF" \
  "7" "Do not create .DS_Store files on network volumes" "OFF" \
  "8" "Disable warning when emptying Trash" "OFF" \
  2>&1 1>&3)

# Close file descriptor 3
exec 3>&-

if [ -z "$CHOICES" ]; then
  clear
  
  echo "No changes made to macOS settings"
else
  for CHOICE in $CHOICES; do
    case "$CHOICE" in
    "1")
      defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
      defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
      ;;
    "2")
      defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
      defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
      ;;
    "3")
      defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true
      ;;
    "4")
      defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
      ;;
    "5")
      defaults write com.apple.screencapture type -string "png"
      ;;
    "6")
      defaults write NSGlobalDomain AppleShowAllExtensions -bool true
      ;;
    "7")
      defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
      ;;
    "8")
      defaults write com.apple.finder WarnOnEmptyTrash -bool false
      ;;
    esac
  done

  clear
fi
