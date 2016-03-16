# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="strug"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=7

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(sudo git git-flow brew)
source $ZSH/oh-my-zsh.sh

# User configuration

# Determine the running OS
platform="unkown"
unamestr=$(uname -s)
if [[ "$unamestr" == 'Linux' ]]; then
    platform="linux"
elif [[ "$unamestr" == 'Darwin' ]]; then
    platform="osx"
fi

export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin"
export MANPATH="/usr/local/man:$MANPATH"

# ZSH syntax highlighting
test -e /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
&& source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
test -e /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
&& source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# You may need to manually set your language environment
export LANG=en_GB.UTF-8

# Preferred editor for local and remote sessions
export EDITOR='vim'

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias auao="sudo apt update && apt list --upgradable"
alias aupg="sudo apt upgrade"
alias aurup="sudo aura -Akua"
alias brewcurl="/usr/local/opt/curl/bin/curl"
alias brewssl="/usr/local/opt/openssl/bin/openssl"
alias irc="ssh lease -t '. ~/.zshrc; tmux attach -t irc'"
test "$platform" = 'linux' && alias ls="ls -F --color=always"
test "$platform" = 'osx' && alias ls="ls -FG"
alias phpunit="phpdbg -qrr vendor/bin/phpunit"
alias pipup="pip3 freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip3 install -U"
alias startace="acestreamengine --client-console --upload-limit 0 --download-limit 0"
alias up="sudo pacman -Syu"

# Brew ZSH stuff
#unalias run-help
#autoload run-help
#HELPDIR=/usr/local/share/zsh/hel

# Go Lang stuff
export GOPATH=$HOME/Development/go
export PATH="$PATH:/usr/local/opt/go/libexec/bin:$GOPATH/bin"

# GnuPG stuff
GPG_TTY=`tty`
export GPG_TTY

# composer global
test "$platform" = 'linux' && export PATH="$PATH:/home/jonny/.composer/vendor/bin"
test "$platform" = 'osx' && export PATH="$PATH:/Users/jonny/.composer/vendor/bin"

# Set the DEFAULT_USER variable to me (jonny)
export DEFAULT_USER="jonny"

# Colourised output for `ls`
export CLICOLOR=true
export CLICOLOR_FORCE=true
export LSCOLORS='dxfxcxdxbxegedabagacad'
export LS_COLORS='di=33;40:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=34;46:cd=34;43:su=0;41:sg=0;46:tw=0;42:ow=0;43:'

test -e ${HOME}/.iterm2_shell_integration.zsh && source ${HOME}/.iterm2_shell_integration.zsh
