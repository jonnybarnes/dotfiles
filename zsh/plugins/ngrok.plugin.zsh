#!/usr/bin/env zsh

# ngrok completions
if command -v ngrok &>/dev/null; then
  eval "$(ngrok completion)"
fi
