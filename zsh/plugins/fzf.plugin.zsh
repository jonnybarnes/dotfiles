#!/usr/bin/env zsh

# Setup fzf completions
if (( ${+commands[fzf]} )); then
  eval "$(fzf --zsh)"
fi
