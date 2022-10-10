# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"
# Fig pre block. Keep at the top of this file.

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
export EDITOR='vim'

# Set the DEFAULT_USER variable to me (jonny)
export DEFAULT_USER="jonny"

# Autoadd to PATH (neede for MacTex)
# It prepends to $PATH, so we do it first then add our own
if [[ -f /usr/libexec/path_helper ]]; then
  eval $(/usr/libexec/path_helper)
fi

# Add our own dirs to the $PATH
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/opt/homebrew/sbin:/usr/local/sbin:/usr/sbin:/sbin:$HOME/.local/bin:$PATH"
export MANPATH="/opt/homebrew/manpages:/usr/local/man:$MANPATH"

# Determine the running OS
source $HOME/.zsh/platform.zsh

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
auto-ls () {
  emulate -L zsh;

  exa --oneline --long --classify --icons --header
}
chpwd_functions=( auto-ls $chpwd_functions )

# Go Lang stuff
export GOPATH=$HOME/go
export PATH="$PATH:$(brew --prefix)/go/bin:$(brew --prefix)/opt/go/libexec/bin:$GOPATH/bin"

# GnuPG stuff
GPG_TTY=`tty`
export GPG_TTY

# Add various GNU functions
export PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:$PATH"
export PATH="$(brew --prefix)/opt/findutils/libexec/gnubin:$PATH"
export PATH="$(brew --prefix)/opt/gnu-sed/libexec/gnubin:$PATH"
export PATH="$(brew --prefix)/opt/grep/libexec/gnubin:$PATH"

# Add Totara Docker helper functions
export PATH="$PATH:$HOME/git/totara-docker-dev/bin"

# Set the rip (Rm ImProved) graveyard
export GRAVEYARD="$HOME/.local/share/Trash"

# composer global
export PATH="$PATH:$HOME/.composer/vendor/bin"

# rust/cargo bin PATH
export PATH="$PATH:$HOME/.cargo/bin"

# Ruby PATH
export PATH="$PATH:$(brew --prefix)/opt/ruby/bin:$HOME/.gem/ruby/2.4.0/bin"

# PostgreSQL binaries
test -d $(brew --prefix)/pgsql && export PATH="$PATH:$(brew --prefix)/pgsql/bin"

# PHP binaries
test -d $HOME/.php/bin && export PATH="$PATH:$HOME/.php/bin"

# macOS Python User binaries
test -d $HOME/Library/Python/3.7/bin && export PATH="$PATH:$HOME/Library/Python/3.7/bin"

# JetBrains Toolbox scripts
test -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" && export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# Homebrew cURL if we have it
test -d $(brew --prefix)/opt/curl && export PATH="$(brew --prefix)/opt/curl/bin:$PATH"

# Set Homebrew Env variables
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_AUTO_UPDATE_SECS=3600
export HOMEBREW_INSTALL_FROM_API=true

# Colourised output for `ls`
export CLICOLOR=true
export CLICOLOR_FORCE=true
export LSCOLORS='dxfxcxdxbxegedabagacad'
export LS_COLORS='di=33;40:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=34;46:cd=34;43:su=0;41:sg=0;46:tw=0;42:ow=0;43:'

# Source my own functions
test -e $HOME/.zsh/functions.zsh && source $HOME/.zsh/functions.zsh

# Source the iTerm2 shell integration
test -e ${HOME}/.iterm2_shell_integration.zsh && source ${HOME}/.iterm2_shell_integration.zsh

# Source the untracked `extra` file
test -e $HOME/.extra && source $HOME/.extra

# Init the fuck
if type thefuck > /dev/null; then
  eval "$(thefuck --alias)"
fi

# https://github.com/wfxr/forgit
test -e $HOME/git/forgit/forgit.plugin.zsh && source $HOME/git/forgit/forgit.plugin.zsh

# McFly
if type mcfly > /dev/null; then
  eval "$(mcfly init zsh)"
fi

# Init starship prompt -- https://starship.rs
eval "$(starship init zsh)"

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"
