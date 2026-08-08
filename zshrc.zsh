# User configuration
# history
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt share_history

# vim binddings
bindkey -v

# You may need to manually set your language environment
export LANG=en_GB.UTF-8

# Preferred editor for local and remote sessions
export EDITOR=nvim

# Add our own dirs to the $PATH
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
export PATH="$HOME/.local/bin:$PATH"

# Go Lang stuff
export GOPATH=$HOME/go

# Homebrew-managed tools
if (( ${+commands[brew]} )); then
  # GNU functions are NOT put on the PATH under their un-prefixed names.
  # Shadowing BSD stat/date/sed/grep silently breaks scripts that expect the
  # macOS versions (portable scripts probe with `stat -f` / `date -j` first).
  # Homebrew still installs the g-prefixed variants in $HOMEBREW_PREFIX/bin,
  # so use gstat / gdate / gsed / ggrep / gfind when you want GNU behaviour.

  # Homebrew cURL if we have it
  test -d $HOMEBREW_PREFIX/opt/curl && export PATH="$HOMEBREW_PREFIX/opt/curl/bin:$PATH"

  # Go
  export PATH="$PATH:$HOMEBREW_PREFIX/go/bin:$HOMEBREW_PREFIX/opt/go/libexec/bin:$GOPATH/bin"

  # Ruby
  export PATH="$PATH:$HOMEBREW_PREFIX/opt/ruby/bin"

  # PostgreSQL binaries
  test -d $HOMEBREW_PREFIX/pgsql && export PATH="$PATH:$HOMEBREW_PREFIX/pgsql/bin"
fi

# Add Obsidian CLI
export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"

# Add Totara Docker helper functions
export PATH="$PATH:$HOME/git/totara-docker-dev/bin"

# phpactor installed manually
export PATH="$PATH:$HOME/git/phpactor/bin"

# rust/cargo bin PATH
export PATH="$PATH:$HOME/.cargo/bin"

# PHP binaries
test -d $HOME/.php/bin && export PATH="$PATH:$HOME/.php/bin"

# JetBrains Toolbox scripts
test -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" && export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# Local Docker if set up that way
test -d $HOME/.docker/bin && export PATH="$HOME/.docker/bin:$PATH"

# credit Paul Irish: https://github.com/paulirish/dotfiles/blob/606d85f083eb53853789ce9dcaf31a49756471bd/.zshrc#L80
# Automatically list directory contents on `cd`.
# Switched to using `eza` instead of `ls`.
ezacd () {
  emulate -L zsh;

  eza --oneline --long --classify --icons --header
}
# Initialize chpwd_functions if it doesn't exist
typeset -ga chpwd_functions
# Only add ezacd to chpwd_functions if it's not already there
if [[ ${chpwd_functions[(ie)ezacd]} -gt ${#chpwd_functions} ]]; then
  chpwd_functions=(${chpwd_functions[@]} "ezacd")
fi

## Set env vars for configuration purposes
# Set colour scheme for bat
export BAT_THEME_LIGHT="GitHub"
export BAT_THEME_DARK="Sublime Snazzy"

# Rainfrog config
export RAINFROG_CONFIG=~/.config/rainfrog

# Source the untracked `extra` file
test -e $HOME/.extra && source $HOME/.extra

# Auto quote pasted URLs
autoload -U url-quote-magic
zle -N self-insert url-quote-magic

# Load plugins via Sheldon, caching the generated source to avoid forking
# sheldon on every startup. Regenerate when the config (plugins.toml) or the
# lock file (touched by `sheldon update`/`--lock`) is newer than the cache.
if (( ${+commands[sheldon]} )); then
  sheldon_cache="$HOME/.cache/sheldon/source.zsh"
  sheldon_toml="$HOME/.config/sheldon/plugins.toml"
  sheldon_lock="$HOME/.local/share/sheldon/plugins.lock"
  if [[ ! -r "$sheldon_cache" || "$sheldon_toml" -nt "$sheldon_cache" || "$sheldon_lock" -nt "$sheldon_cache" ]]; then
    mkdir -p "${sheldon_cache:h}"
    sheldon source > "$sheldon_cache"
  fi
  source "$sheldon_cache"
  unset sheldon_cache sheldon_toml sheldon_lock
fi

# Set the prompt
# We need zsh git integration
# Autoload zsh's `add-zsh-hook` and `vcs_info` functions
# (-U autoload w/o substition, -z use zsh style)
autoload -Uz add-zsh-hook vcs_info

# Set prompt substitution so we can use the vcs_info_message variable
setopt prompt_subst

# Run the `vcs_info` hook to grab git info before displaying the prompt
add-zsh-hook precmd vcs_info

# Style the vcs_info message
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git*' formats '⎇ %b'
# Format when the repo is in an action (merge, rebase, etc)
zstyle ':vcs_info:git*' actionformats '%F{14}⏱ %*%f'

# First show the Loading indicator in the right prompt if shell plugins are
# still loading. `${SHELL_LOADING:+...}` expands inline with no subshell fork.
RPROMPT='%F{8}${SHELL_LOADING:+Loading... }'

# Then we can also show the git branch
RPROMPT+='${vcs_info_msg_0_}'

# First set a dot that changes colour on success/fail of the previous command
PROMPT='%(?.%F{blue}⏺.%F{red}⏺)%f '
# Show a symbol for the OS
# First we set the os_symbol variable we will use in the prompt
if [[ "$OSTYPE" == "darwin"* ]]; then
    os_symbol=""
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    os_symbol="󰣇"
else
    os_symbol=""  # Fallback symbol if OS is neither macOS nor Linux
fi

PROMPT+='${os_symbol} '
# Then show the working directory
PROMPT+='%2~ '
# Finally we can adjust the prompt to show if we are a user or sudo
PROMPT+='%(!.#.$) '

# Finally we can have zsh auto source this rc file on command
# attribution: https://www.reddit.com/r/commandline/comments/12g76v/
trap "source $HOME/.zshrc" USR1

