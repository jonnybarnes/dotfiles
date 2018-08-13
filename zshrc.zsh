# User configuration
# history
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
# vim binddings
bindkey -v
# ZSH builtin autoload
autoload -Uz compinit promptinit run-help
compinit
promptinit
unalias run-help
alias help=run-help
# Persistant rehash to find new programs in the $PATH
zstyle ':completion:*' rehash true

# You may need to manually set your language environment
export LANG=en_GB.UTF-8

# Preferred editor for local and remote sessions
export EDITOR='vim'

# Set the DEFAULT_USER variable to me (jonny)
export DEFAULT_USER="jonny"

# Set the $PATH
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:$HOME/.local/bin"
export MANPATH="/usr/local/man:$MANPATH"

# Determine the running OS
source $HOME/.zsh/platform.zsh

# Set a powerline prompt
source $HOME/.zsh/powerline-prompt.zsh

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
auto-ls () {
    emulate -L zsh;
    # explicit sexy ls'ing as aliases arent honored in here.
    hash gls >/dev/null 2>&1 && CLICOLOR_FORCE=1 gls -aFh --color --group-directories-first || ls
}
chpwd_functions=( auto-ls $chpwd_functions )

# Go Lang stuff
test $PLATFORM = 'linux' && export GOPATH=$HOME/go
test $PLATFORM = 'osx' && export GOPATH=$HOME/Development/go
export PATH="$PATH:/usr/local/go/bin:/usr/local/opt/go/libexec/bin:$GOPATH/bin"

# GnuPG stuff
GPG_TTY=`tty`
export GPG_TTY

# composer global
export PATH="$PATH:$HOME/.composer/vendor/bin"

# rust/cargo bin PATH
export PATH="$PATH:$HOME/.cargo/bin"

# Ruby PATH
export PATH="$PATH:$HOME/.gem/ruby/2.4.0/bin"

# PostgreSQL binaries
test -d /usr/local/pgsql && export PATH="$PATH:/usr/local/pgsql/bin"

# PHP binaries
test -d $HOME/.php/bin && export PATH="$PATH:$HOME/.php/bin"

# Set Homebrew Env variables
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_AUTO_UPDATE_SECS=3600

# Colourised output for `ls`
export CLICOLOR=true
export CLICOLOR_FORCE=true
export LSCOLORS='dxfxcxdxbxegedabagacad'
export LS_COLORS='di=33;40:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=34;46:cd=34;43:su=0;41:sg=0;46:tw=0;42:ow=0;43:'

# Add zsh-completions to the fpath
# They are packaged correctly for Arch Linux
test $PLATFORM = 'osx' && fpath=(/usr/local/share/zsh-completions $fpath)

# Source my own functions
test -e $HOME/.zsh/functions.zsh && source $HOME/.zsh/functions.zsh

# Source the iTerm2 shell integration
test -e ${HOME}/.iterm2_shell_integration.zsh && source ${HOME}/.iterm2_shell_integration.zsh

# Source the untracked `extra` file
test -e $HOME/.extra && source $HOME/.extra