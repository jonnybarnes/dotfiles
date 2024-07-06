#!/usr/bin/env zsh

# Setup fzf completions
if type fzf > /dev/null; then
  eval "$(fzf --zsh)"
fi
