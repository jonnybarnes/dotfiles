# ZSH substring search
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
test $PLATFORM = 'osx' && bindKeysZshHistoryOSX
test $PLATFORM = 'linux' && bindKeysZshHistoryLinux