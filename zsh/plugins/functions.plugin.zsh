#!/usr/bin/env zsh

# Functions

# Delete branches selected via fzf
function delete-branches() {
  git branch |
    grep --invert-match '\*' | # Remove current branch
    fzf --multi --preview="git log {..}" |
    gxargs --no-run-if-empty git branch --delete
}

# Delete branches selected via fzf (force the deletion)
function delete-branches-force() {
  git branch |
    grep --invert-match '\*' | # Remove current branch
    fzf --multi --preview="git log {..}" |
    gxargs --no-run-if-empty git branch --delete --force
}

# Open a PR
function pr-checkout() {
  local pr_number

  pr_number=$(
    gh api 'repos/:owner/:repo/pulls' --jq '.[] | "#\(.number) \(.title)"' |
      fzf |
      sd '^\#(\d+)\s.*' '$1'
  )

  if [ -n "$pr_number" ]; then
    gh pr checkout "$pr_number"
  fi
}

# tail, but better
function watch-file() {
  tail -f $1 | bat --paging=never -l log
}

# Get a temporary directory in a cross-platform manner
# See https://unix.stackexchange.com/a/685873
function get-temporary-directory() {
  local temporary_directory=${XDG_RUNTIME_DIR:-${TMPDIR:-${TMP:-${TEMP:-/tmp}}}}

  echo $temporary_directory
}

# Start an SSH SOCKS tunnel
function start-proxy() {
  if [ -z "$SSH_PROXY_HOST" ]; then
    echo "SSH_PROXY_HOST is not set or empty"

    return
  fi

  local socket_dir=$(get-temporary-directory)

  # Check if the last character of socket_dir is a directory separator character
  if [[ $socket_dir[-1] == / ]]; then
    # If yes, remove the directory separator character
    socket_dir="${socket_dir%?}"
  fi

  echo "Opening proxy connection"

  # Below we use -S and -M to help make closing the connection more reliable
  # See this Stack Overflow answer for more info
  # https://unix.stackexchange.com/a/525388

  # -D 1337 opens up the SOXKS tunnel on localhost:1337
  # -f Tells `ssh` to fork the ssh process in to the background
  # -C Enables compression of data on the connections
  # -q Uses quiet mode
  # -N Do not execute a remote command on this connection 
  # -S Set the ControlPath for this connection
  # -M Place the client into `master` mode
  ssh -D 1337 -f -C -q -N -S $socket_dir/ssh-proxy-control -M $SSH_PROXY_HOST
}

# Stop an open proxy connection
function stop-proxy() {
  if [ -z "$SSH_PROXY_HOST" ]; then
    echo "SSH_PROXY_HOST is not set or empty"
    
    return
  fi

  local socket_dir=$(get-temporary-directory)

  # Check if the last character of socket_dir is a directory separator character
  if [[ $socket_dir[-1] == / ]]; then
    # If yes, remove the directory separator character
    socket_dir="${socket_dir%?}"
  fi

  echo "Closing proxy connection"

  # See the comments in `start-proxy()` for more info
  ssh -S $socket_dir/ssh-proxy-control -O exit $SSH_PROXY_HOST
}

# Get the system appearance
function get-system-appearance() {
  if ! type defaults &>/dev/null; then
    echo ""
  fi
  
  local darkMode=true;

  if [[ $(defaults read -g AppleInterfaceStyle 2> /dev/null) != 'Dark' ]]; then
    darkMode=false
  fi

  if [[ $darkMode == true ]]; then
    echo "dark"
  else
    echo "light"
  fi
}
