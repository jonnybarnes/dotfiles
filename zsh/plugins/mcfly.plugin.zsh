#!/usr/bin/env zsh

# McFly
if (( ${+commands[mcfly]} )); then
  eval "$(mcfly init zsh)"
fi
