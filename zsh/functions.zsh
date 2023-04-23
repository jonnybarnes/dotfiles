#!/usr/bin/env zsh

# Functions

# Generate TLS certs using a local CA
gencert () {
    DOMAIN=$1

    test -d /usr/local/opt/openssl@1.1/bin && PATH='/usr/local/opt/openssl@1.1/bin':$PATH
    test -d /opt/homebrew/opt/openssl@1.1/bin && PATH='/opt/homebrew/opt/openssl@1.1/bin':$PATH
    test -f /usr/local/etc/openssl@1.1/openssl.cnf && SSLCNF='/usr/local/etc/openssl@1.1/openssl.cnf'
    test -f /opt/homebrew/etc/openssl@1.1/openssl.cnf && SSLCNF='/opt/homebrew/etc/openssl@1.1/openssl.cnf'
    test -f /etc/ssl/openssl.cnf && SSLCNF='/etc/ssl/openssl.cnf'

    cd $HOME/git/ca
    [[ ! -d $DOMAIN ]] && mkdir $DOMAIN
    cd $DOMAIN
    [[ -f key ]] && mv key key.bak
    [[ -f csr ]] && mv csr csr.bak
    [[ -f crt ]] && mv crt crt.bak

    openssl ecparam -name secp384r1 -genkey -noout -out key
    chmod 644 key
    openssl req -new -sha256 -key key -subj "/C=UK/ST=England/L=Bury/O=JMB Dev Ltd/CN=$DOMAIN" -reqexts SAN -config <(cat $SSLCNF <(printf "[SAN]\nsubjectAltName=DNS:$DOMAIN")) -out csr
    openssl x509 -req -in csr -extfile <(cat $SSLCNF <(printf "[SAN]\nsubjectAltName=DNS:$DOMAIN")) -extensions SAN -CA ../jmb-ca-ecc.pem -CAkey ../jmb-ca-ecc.key -CAcreateserial -days 90 -sha256 -out crt

    cd $HOME/git/ca
    echo 'Certs generated for $DOMAIN'
}

# Generate a random 7 digit number, used for CCL’s ImKeys
imkey () {
    imkey=$(shuf -i 1111111-9999999 -n1)

    echo $imkey
}

# Delete branches selected via fzf
delete-branches () {
    git branch |
        grep --invert-match '\*' | # Remove current branch
        fzf --multi --preview="git log {..}" |
        gxargs --no-run-if-empty git branch --delete
}

# Delete branches selected via fzf (force the deletion)
delete-branches-force () {
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
