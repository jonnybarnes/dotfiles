#!/usr/bin/env zsh

# Current dir
BASEDIR=$(pwd)

# Update git submodules
echo "Updating git submodules"
git submodule init && git submodule update

# ln the various files
echo "Sym-linking the various config files"
test -L $HOME/.curlrc || ln -f -s $BASEDIR/curlrc $HOME/.curlrc
test -L $HOME/.gitignore || ln -f -s $BASEDIR/gitignore $HOME/.gitignore
test -L $HOME/.hushlogin || ln -f -s $BASEDIR/hushlogin $HOME/.hushlogin
test -d $HOME/.ncmpcpp || mkdir $HOME/.ncmpcpp
test -L $HOME/.ncmpcpp/config || ln -f -s $BASEDIR/ncmpcpp $HOME/.ncmpcpp/config
test -L $HOME/.tmux.conf || ln -f -s $BASEDIR/tmux $HOME/.tmux.conf
test -L $HOME/.config/starship.toml || ln -f -s $BASEDIR/starship.toml $HOME/.config/starship.toml
test -d $HOME/.sheldon || mkdir $HOME/.sheldon
test -L $HOME/.sheldon/plugins.toml || ln -f -s $BASEDIR/sheldon.toml $HOME/.sheldon/plugins.toml
test -L $HOME/.zsh || ln -f -s $BASEDIR/zsh $HOME/.zsh
test -L $HOME/.zshrc || ln -f -s $BASEDIR/zshrc.zsh $HOME/.zshrc

# setup gpg conf
test -d $HOME/.gnupg || mkdir $HOME/.gnupg
cp -f $BASEDIR/gnupg/common.conf $HOME/.gnupg/common.conf
cp -f $BASEDIR/gnupg/dirmngr.conf $HOME/.gnupg/dirmngr.conf
cp -f $BASEDIR/gnupg/gpg.conf $HOME/.gnupg/gpg.conf
chmod 700 $HOME/.gnupg
chmod 640 $HOME/.gnupg/common.conf
chmod 640 $HOME/.gnupg/dirmngr.conf
chmod 640 $HOME/.gnupg/gpg.conf

# ln vim files
echo "Setting up vim"
test -d $HOME/.vim && rm -rf $HOME/.vim
ln -s $BASEDIR/vim $HOME/.vim
test -L $HOME/.vimrc || ln -f -s $HOME/.vim/vimrc $HOME/.vimrc

# .gitconfig gets edited by .extra so we won’t symlink it, but copy it
echo "For compatability we chall copy the global gitconfig"
cp $BASEDIR/gitconfig $HOME/.gitconfig

# Source zshrc
echo "And finally, source the .zshrc"
source $HOME/.zshrc
