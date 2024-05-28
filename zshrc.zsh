# User configuration
# history
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000

# vim binddings
bindkey -v

# ZSH builtin autoload
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
  FPATH=$(brew --prefix)/share/zsh/zsh-completions:$FPATH
fi
autoload -Uz compinit promptinit run-help zmv
compinit
promptinit
case $(type run-help) in
  (*alias*) unalias run-help;;
esac
alias help=run-help
# Persistant rehash to find new programs in the $PATH
zstyle ':completion:*' rehash true

# You may need to manually set your language environment
export LANG=en_GB.UTF-8

# Preferred editor for local and remote sessions
export EDITOR='nvim'

# Set the DEFAULT_USER variable to me (jonny)
export DEFAULT_USER="jonny"

# Autoadd to PATH (neede for MacTex)
# It prepends to $PATH, so we do it first then add our own
if [[ -f /usr/libexec/path_helper ]]; then
  eval $(/usr/libexec/path_helper)
fi

# Add our own dirs to the $PATH
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew  shellenv)"
fi
if [[ -f /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew  shellenv)"
fi
export PATH="$HOME/.local/bin:$PATH"

# Source my own functions
source $HOME/.zsh/functions.zsh

# Determine the running OS
source $HOME/.zsh/platform.zsh

# Detect system appearance
export MACOS_APPEARANCE=`get-system-appearance`

# ZSH syntax highlighting
source $HOME/.zsh/zsh-syntax-highlighting.zsh

# ZSH history substring search
source $HOME/.zsh/zsh-substring-search.zsh

# ZSH autosuggestions
source $HOME/.zsh/zsh-autosuggestions.zsh

# Aliases
source $HOME/.zsh/aliases.zsh

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
if type brew &>/dev/null; then
  export PATH="$PATH:$(brew --prefix)/go/bin:$(brew --prefix)/opt/go/libexec/bin:$GOPATH/bin"
fi
# GnuPG stuff
GPG_TTY=`tty`
export GPG_TTY

# Add various GNU functions
if type brew &>/dev/null; then
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
if type brew &>/dev/null; then
  export PATH="$PATH:$(brew --prefix)/opt/ruby/bin:$HOME/.gem/ruby/2.4.0/bin"
fi

# PostgreSQL binaries
if type brew &>/dev/null; then
  test -d $(brew --prefix)/pgsql && export PATH="$PATH:$(brew --prefix)/pgsql/bin"
fi

# PHP binaries
test -d $HOME/.php/bin && export PATH="$PATH:$HOME/.php/bin"

# JetBrains Toolbox scripts
test -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" && export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# Homebrew cURL if we have it
if type brew &>/dev/null; then
  test -d $(brew --prefix)/opt/curl && export PATH="$(brew --prefix)/opt/curl/bin:$PATH"
fi

# Colourised output for `ls`
# export CLICOLOR=true
# export CLICOLOR_FORCE=true
# export LSCOLORS='dxfxcxdxbxegedabagacad'
# export LS_COLORS='di=33;40:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=34;46:cd=34;43:su=0;41:sg=0;46:tw=0;42:ow=0;43:'
# vivid Dark mode   ayu
# vivid Light mode  snazzy
if type vivid &>/dev/null; then
  local vividTheme="ayu"
  if [[ $MACOS_APPEARANCE == "light" ]]; then
    vividTheme="catppuccin-latte"
  fi
  
  export LS_COLORS="$(vivid generate $vividTheme)"
fi

# Set colour scheme got bat
# bat Dark mode   OneHalfDark
# bat Light mode  Coldark-Dark
local batTheme="OneHalfDark"
if [[ $MACOS_APPEARANCE == "light" ]]; then
  batTheme="gruvbox-light"
fi
export BAT_THEME=$batTheme

# Setup fzf completions
export FZF_COMPLETION_TRIGGER='~~'
if type fzf > /dev/null; then
  eval "$(fzf --zsh)"
fi

# Source the iTerm2 shell integration
test -e ${HOME}/.iterm2_shell_integration.zsh && source ${HOME}/.iterm2_shell_integration.zsh

# Source the untracked `extra` file
test -e $HOME/.extra && source $HOME/.extra

# You Should Use
test -e /opt/homebrew/share/zsh-you-should-use/you-should-use.plugin.zsh && source /opt/homebrew/share/zsh-you-should-use/you-should-use.plugin.zsh
test -e /usr/share/zsh/plugins/zsh-you-should-use/you-should-use.plugin.zsh && source /usr/share/zsh/plugins/zsh-you-should-use/you-should-use.plugin.zsh

# Setup Fast Node Manager
if type fnm > /dev/null; then
  eval "$(fnm env --use-on-cd)"
fi

# Setup GitHub Copilot
# first check we even have the genereic `gh` command
if type gh > /dev/null; then
  # Now check we have the copilot plugin installed with `gh`
  if gh extension list | rg copilot -c > /dev/null; then
    eval "$(gh copilot alias -- zsh)"
  fi
fi

# Init the fuck
if type thefuck > /dev/null; then
  eval "$(thefuck --alias)"
fi

# https://github.com/wfxr/forgit
test -e $HOME/git/forgit/forgit.plugin.zsh && source $HOME/git/forgit/forgit.plugin.zsh
test -e $HOME/git/forgit/completionsgit-forgit.zsh && source $HOME/git/forgit/completionsgit-forgit.zsh

# McFly
if type mcfly > /dev/null; then
  eval "$(mcfly init zsh)"
fi

# ngrok completions
if command -v ngrok &>/dev/null; then
  eval "$(ngrok completion)"
fi

# zoxide - a better `cd` command
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# Init starship prompt -- https://starship.rs
eval "$(starship init zsh)"

# Finally we can have zsh auto source this rc file on command
# attribution: https://www.reddit.com/r/commandline/comments/12g76v/
trap "source $HOME/.zshrc" USR1
