# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="agnoster"

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
plugins=(git git-flow)
source $ZSH/oh-my-zsh.sh

# User configuration
# history
SAVEHIST=100000

# vim binddings
bindkey -v

# Source the untracked `extra` file
test -e $HOME/.extra && source $HOME/.extra

# Source VTE for Terminix
if [ $TERMINIX_ID ] || [ $VTE_VERSION ]; then
        source /etc/profile.d/vte.sh
fi

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

# ZSH history substring search
bindKeysZshHistoryOSX() {
    zmodload zsh/terminfo
    bindkey "$terminfo[kcuu1]" history-substring-search-up
    bindkey "$terminfo[kcud1]" history-substring-search-down
}
bindKeysZshHistoryLinux() {
    zmodload zsh/terminfo
    bindkey "$terminfo[cuu1]" history-substring-search-up
    bindkey "$terminfo[cud1]" history-substring-search-down
}
test -e /usr/local/opt/zsh-history-substring-search/zsh-history-substring-search.zsh \
&& source /usr/local/opt/zsh-history-substring-search/zsh-history-substring-search.zsh
test -e /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh \
&& source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
test "$platform" = 'osx' && bindKeysZshHistoryOSX
test "$platform" = 'linux' && bindKeysZshHistoryLinux

# ZSH autosuggestions
test -e /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
&& source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
test -e /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
&& source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

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
alias bubc="brew upgrade && brew cleanup"
alias bubo="brew update && brew outdated"
alias brewcurl="/usr/local/opt/curl/bin/curl --cacert /usr/local/etc/openssl/cert.pem"
alias brewssl="/usr/local/opt/openssl@1.1/bin/openssl"
alias ga="git add"
alias gf="git fetch --all; git fetch --tags"
alias git="hub"
alias gs="git status"
alias irc="ssh jmb -t '. ~/.zshrc; tmux attach -t irc'"
test "$platform" = 'linux' && alias ls="ls -F --color=always"
test "$platform" = 'osx' && alias ls="ls -FG"
test "$platform" = 'linux' && alias pipup="pip freeze --local | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 sudo pip install -U"
test "$platform" = 'osx' && alias pipup="pip3 freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip3 install -U"
alias rtor="tmux attach -t rtor"
alias startace="acestreamengine --client-console --upload-limit 0 --download-limit 0"
alias up="sudo pacman -Syu"

# Brew ZSH stuff
#unalias run-help
#autoload run-help
#HELPDIR=/usr/local/share/zsh/help

# credit Paul Irish: https://github.com/paulirish/dotfiles/blob/606d85f083eb53853789ce9dcaf31a49756471bd/.zshrc#L80
# Automatically list directory contents on `cd`.
auto-ls () {
    emulate -L zsh;
    # explicit sexy ls'ing as aliases arent honored in here.
    hash gls >/dev/null 2>&1 && CLICOLOR_FORCE=1 gls -aFh --color --group-directories-first || ls
}
chpwd_functions=( auto-ls $chpwd_functions )

# Go Lang stuff
test "$platform" = 'linux' && export GOPATH=$HOME/go
test "$platform" = 'osx' && export GOPATH=$HOME/Development/go
export PATH="$PATH:/usr/local/go/bin:/usr/local/opt/go/libexec/bin:$GOPATH/bin"

# GnuPG stuff
GPG_TTY=`tty`
export GPG_TTY

# composer global
test "$platform" = 'linux' && export PATH="$PATH:/home/jonny/.composer/vendor/bin"
test "$platform" = 'osx' && export PATH="$PATH:/Users/jonny/.composer/vendor/bin"

# rust/cargo bin PATH
export PATH="$PATH:$HOME/.cargo/bin"

# Ruby PATH
export PATH="$PATH:$HOME/.gem/ruby/2.4.0/bin"

# PostgreSQL binaries
test -d /usr/local/pgsql && export PATH="$PATH:/usr/local/pgsql/bin"

# PHP binaries
test -d $HOME/.php/bin && export PATH="$PATH:$HOME/.php/bin"

# Set the DEFAULT_USER variable to me (jonny)
export DEFAULT_USER="jonny"

# No Homebrew analytics
export HOMEBREW_NO_ANALYTICS=1

# Colourised output for `ls`
export CLICOLOR=true
export CLICOLOR_FORCE=true
export LSCOLORS='dxfxcxdxbxegedabagacad'
export LS_COLORS='di=33;40:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=34;46:cd=34;43:su=0;41:sg=0;46:tw=0;42:ow=0;43:'

# Add zsh-completions to the fpath
# They are packaged correctly for Arch Linux
test "$platform" = 'osx' && fpath=(/usr/local/share/zsh-completions $fpath)

# Source my own functions
test -e $HOME/.functions.zsh && source $HOME/.functions.zsh

test -e ${HOME}/.iterm2_shell_integration.zsh && source ${HOME}/.iterm2_shell_integration.zsh
