#!/usr/bin/env zsh

# Functions

# Generate TLS certs using a local CA
gencert () {
    DOMAIN=$1

    test -d /usr/local/opt/openssl@1.1/bin && PATH='/usr/local/opt/openssl@1.1/bin':$PATH
    test -f /usr/local/etc/openssl@1.1/openssl.cnf && SSLCNF='/usr/local/etc/openssl@1.1/openssl.cnf'
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

function watch-file() {
    tail -f $1 | bat --paging=never -l log
}
