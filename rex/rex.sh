#!/usr/bin/env zsh

# rex.sh
# Apply the Rex terminal settings that live in macOS defaults rather than in
# init.lua: the tangere light/dark themes (imported from the ghostty theme
# files), the font and copy-on-select. Run it with Rex quit, otherwise Rex
# overwrites the values with its in-memory copy when it next saves.

if pgrep -xq Rex; then
  echo "Quit Rex before running this script"
  exit 1
fi

BASEDIR=${0:A:h}
DOMAIN=com.superlogical.rex

# Without this check a missing file would write empty data and wipe the themes
if [[ ! -r $BASEDIR/themes.json ]]; then
  echo "Cannot read $BASEDIR/themes.json"
  exit 1
fi

# Custom themes are a JSON array stored as data. themes.json is the decoded
# blob Rex wrote after importing ghostty/themes/tangere-{dark,light}; the IDs
# below are the ones inside it, so re-exporting the blob means updating both.
defaults write $DOMAIN Workspace.customThemes -data "$(xxd -p "$BASEDIR/themes.json" | tr -d '\n')"
defaults write $DOMAIN Workspace.darkThemeID -string custom-3FE5CE8B-4687-4632-864F-7DFB39C94764
defaults write $DOMAIN Workspace.lightThemeID -string custom-82BA2A60-D9EA-4808-811D-6E1EA369C1E7

# Font and selection behaviour, matching the ghostty config. "Improve text
# contrast" (ghostty's minimum-contrast) is Rex's default and writes no key.
defaults write $DOMAIN Workspace.terminalFontName -string "Hack Nerd Font Mono"
defaults write $DOMAIN Workspace.terminalFontPointSize -float 18
defaults write $DOMAIN Workspace.terminalCopyOnSelect -bool true
