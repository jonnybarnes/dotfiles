#!/usr/bin/env zsh

# Setup Fast Node Manager
if type fnm > /dev/null; then
  eval "$(fnm env --use-on-cd)"
fi
