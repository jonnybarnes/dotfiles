#!/usr/bin/env zsh

# Setup GitHub Copilot
# first check we even have the genereic `gh` command
if type gh > /dev/null; then
  # Now check we have the copilot plugin installed with `gh`
  if gh extension list | rg copilot -c > /dev/null; then
    eval "$(gh copilot alias -- zsh)"
  fi
fi
