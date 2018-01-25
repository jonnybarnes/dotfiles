# Powerline prompt

powerline-daemon -q

test $PLATFORM = 'osx' \
&& source /usr/local/lib/python3.6/site-packages/powerline/bindings/zsh/powerline.zsh
test $PLATFORM = 'linux' \
&& source /usr/lib/python3.6/site-packages/powerline/bindings/zsh/powerline.zsh