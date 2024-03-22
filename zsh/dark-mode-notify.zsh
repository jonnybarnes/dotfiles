#!/usr/bin/env zsh

function switch-dark-mode()
{
  local darkMode=true;

  if [[ $(defaults read -g AppleInterfaceStyle 2> /dev/null) != 'Dark' ]]; then
    darkMode=false
  fi

  if [[ $darkMode == true ]]; then
    echo "Switched to dark mode"
    export MACOS_APPEARANCE="dark"
  else
    echo "Switched to light mode"
    export MACOS_APPEARANCE="light"
  fi

  # Reload zshrc
  pkill -usr1 zsh
}

switch-dark-mode
