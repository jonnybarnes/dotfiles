#!/usr/bin/env zsh

# Init the fuck
if (( ${+commands[thefuck]} )); then
  eval "$(thefuck --alias)"
fi
