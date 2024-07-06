#!/usr/bin/env zsh

# ngrok completions
if (( ${+commands[ngrok]} )); then
  eval "$(ngrok completion)"
fi
