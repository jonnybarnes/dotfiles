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

# Add yay+fzf alias
alias yayf="yay -Slq | fzf --multi --preview 'yay -Sii {1}' --preview-window=down:75% --layout=reverse | xargs -ro yay -S"
