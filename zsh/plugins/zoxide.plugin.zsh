#!/usr/bin/env zsh

# zoxide - a better `cd` command
if (( ${+commands[zoxide]} )); then
  eval "$(zoxide init zsh)"
fi
