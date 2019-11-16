# Powerline prompt

powerline-daemon -q

test -e '/usr/local/lib/python3.6/site-packages/powerline/bindings/zsh/powerline.zsh' \
    && source /usr/local/lib/python3.6/site-packages/powerline/bindings/zsh/powerline.zsh
test -e '/usr/lib/python3.7/site-packages/powerline/bindings/zsh/powerline.zsh' \
    && source /usr/lib/python3.7/site-packages/powerline/bindings/zsh/powerline.zsh
test -e '/usr/lib/python3.6/site-packages/powerline/bindings/zsh/powerline.zsh' \
    && source /usr/lib/python3.6/site-packages/powerline/bindings/zsh/powerline.zsh
test -e '/home/jonny/.local/lib/python3.5/site-packages/powerline/bindings/zsh/powerline.zsh' \
    && source /home/jonny/.local/lib/python3.5/site-packages/powerline/bindings/zsh/powerline.zsh
test -e '/usr/lib/python3.8/site-packages/powerline/bindings/zsh/powerline.zsh' \
    && source /usr/lib/python3.8/site-packages/powerline/bindings/zsh/powerline.zsh