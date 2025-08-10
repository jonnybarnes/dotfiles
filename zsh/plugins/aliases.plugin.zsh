#!/usr/bin/env zsh

# Homebrew commands
alias bubc="brew upgrade && brew cleanup"
alias bubo="brew update && brew outdated"

# Use eza instead of ls
alias eza="eza --oneline --long --classify --icons --header"

# Laravel Sail
alias sail="[ -f sail ] && bash sail || bash vendor/bin/sail"

# Add git aliases
alias gs="git status"
