# User configuration
# history
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000

# vim binddings
bindkey -v

# You may need to manually set your language environment
export LANG=en_GB.UTF-8

# Preferred editor for local and remote sessions
export EDITOR=nvim

# Autoadd to PATH (neede for MacTex)
# It prepends to $PATH, so we do it first then add our own
if [[ -f /usr/libexec/path_helper ]]; then
  eval $(/usr/libexec/path_helper)
fi

# Add our own dirs to the $PATH
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
if [[ -f /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
export PATH="$HOME/.local/bin:$PATH"

# credit Paul Irish: https://github.com/paulirish/dotfiles/blob/606d85f083eb53853789ce9dcaf31a49756471bd/.zshrc#L80
# Automatically list directory contents on `cd`.
# Switched to using `exa` instead of `ls`.
ezacd () {
  emulate -L zsh;

  eza --oneline --long --classify --icons --header
}
chpwd_functions=(${chpwd_functions[@]} "ezacd")

# Go Lang stuff
export GOPATH=$HOME/go
if (( ${+commands[brew]} )); then
  export PATH="$PATH:$(brew --prefix)/go/bin:$(brew --prefix)/opt/go/libexec/bin:$GOPATH/bin"
fi

# Add various GNU functions
# Prepend them to the PATH so they override any system installed versions
if (( ${+commands[brew]} )); then
  export PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:$PATH"
  export PATH="$(brew --prefix)/opt/findutils/libexec/gnubin:$PATH"
  export PATH="$(brew --prefix)/opt/gnu-sed/libexec/gnubin:$PATH"
  export PATH="$(brew --prefix)/opt/grep/libexec/gnubin:$PATH"
fi

# Add Totara Docker helper functions
export PATH="$PATH:$HOME/git/totara-docker-dev/bin"

# Set the rip (Rm ImProved) graveyard
export GRAVEYARD="$HOME/.local/share/Trash"

# composer global
export PATH="$PATH:$HOME/.composer/vendor/bin"

# rust/cargo bin PATH
export PATH="$PATH:$HOME/.cargo/bin"

# Ruby PATH
if (( ${+commands[brew]} )); then
  export PATH="$PATH:$(brew --prefix)/opt/ruby/bin"
fi

# PostgreSQL binaries
if (( ${+commands[brew]} )); then
  test -d $(brew --prefix)/pgsql && export PATH="$PATH:$(brew --prefix)/pgsql/bin"
fi

# PHP binaries
test -d $HOME/.php/bin && export PATH="$PATH:$HOME/.php/bin"

# JetBrains Toolbox scripts
test -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" && export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# Homebrew cURL if we have it
if (( ${+commands[brew]} )); then
  test -d $(brew --prefix)/opt/curl && export PATH="$(brew --prefix)/opt/curl/bin:$PATH"
fi


# Load plugins via Sheldon
if (( ${+commands[sheldon]} )); then
  eval "$(sheldon source)"
fi

# Detect system appearance
export MACOS_APPEARANCE=`get-system-appearance`

# Colourised output for `ls`
# vivid Dark mode   ayu
# vivid Light mode  catppuccin-latte
if type vivid &>/dev/null; then
  local vividTheme="ayu"
  if [[ $MACOS_APPEARANCE == "light" ]]; then
    vividTheme="catppuccin-latte"
  fi

  export LS_COLORS="$(vivid generate $vividTheme)"
fi

# Set colour scheme got bat
# bat Dark mode   OneHalfDark
# bat Light mode  gruvbox-light
local batTheme="OneHalfDark"
if [[ $MACOS_APPEARANCE == "light" ]]; then
  batTheme="gruvbox-light"
fi
export BAT_THEME=$batTheme

# Source the untracked `extra` file
test -e $HOME/.extra && source $HOME/.extra

# Oh My Posh
if (( ${+commands[oh-my-posh]} )); then
  eval "$(oh-my-posh init zsh --config $HOME/.config/jmb.omp.toml)"
fi

# Finally we can have zsh auto source this rc file on command
# attribution: https://www.reddit.com/r/commandline/comments/12g76v/
trap "source $HOME/.zshrc" USR1
