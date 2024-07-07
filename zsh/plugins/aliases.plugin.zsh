#!/usr/bin/env zsh

# Homebrew commands
alias bubc="brew upgrade && brew cleanup"
alias bubo="brew update && brew outdated"

# See which user or profile we are authneticated as in aws-cli
alias aws-whoami="aws sts get-caller-identity"

# Use eza instead of ls
alias als="eza --oneline --long --classify --icons --header"

# Laravel Sail
alias sail="[ -f sail ] && bash sail || bash vendor/bin/sail"

# Add git aliases
alias gs="git status"
