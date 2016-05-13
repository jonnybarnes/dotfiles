#!/usr/bin/env zsh

# Current dir
BASEDIR=$(pwd)

# ln the various files
test -L $HOME/.curlrc || ln -f -s $BASEDIR/curlrc $HOME/.curlrc
test -L $HOME/.gitignore || ln -f -s $BASEDIR/gitignore $HOME/.gitignore
test -L $HOME/.hushlogin || ln -f -s $BASEDIR/hushlogin $HOME/.hushlogin
test -L $HOME/.zshrc || ln -f -s $BASEDIR/zshrc $HOME/.zshrc

# ln vim files
test -L $HOME/.vim || ln -f -s $BASEDIR/vim $HOME/.vim
test -L $HOME/.vimrc || ln -f -s $HOME/.vim/vimrc $HOME/.vimrc

# .gitconfig gets edited by .extra so we won’t symlink it, but copy it
cp $BASEDIR/gitconfig $HOME/.gitconfig

# Source zshrc
source $HOME/.zshrc
