# fzf completions
test -e /opt/homebrew/opt/fzf/shell/completion.zsh && source /opt/homebrew/opt/fzf/shell/completion.zsh
test -e /usr/share/fzf/completion.zsh && source /usr/share/fzf/completion.zsh

# cURL completions copied from https://blog.revathskumar.com/2024/02/curl-fuzzy-search-options-using-fzf.html
_fzf_complete_curl() {
  _fzf_complete --header-lines=1  --prompt="curl> " -- "$@" < <(
    curl -h all
  )
}

_fzf_complete_curl_post() {
  awk '{print $1}' | cut -d ',' -f -1
}
