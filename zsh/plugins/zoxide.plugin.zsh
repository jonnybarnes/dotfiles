#!/usr/bin/env zsh

# zoxide - a better `cd` command
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi
