#!/usr/bin/env zsh

# Current dir
BASEDIR=$(pwd)

# Update git submodules
echo "Updating git submodules"
git submodule init && git submodule update

# ln the various files
echo "Sym-linking the various config files"
test -L $HOME/.gitignore || ln -f -s $BASEDIR/gitignore $HOME/.gitignore
test -L $HOME/.hushlogin || ln -f -s $BASEDIR/hushlogin $HOME/.hushlogin
test -L $HOME/.tmux.conf || ln -f -s $BASEDIR/tmux $HOME/.tmux.conf
test -L $HOME/.config/starship.toml || ln -f -s $BASEDIR/starship.toml $HOME/.config/starship.toml
test -L $HOME/.config/jmb.omp.toml || ln -f -s $BASEDIR/jmb.omp.toml $HOME/.config/jmb.omp.toml
test -d $HOME/.config/sheldon || mkdir $HOME/.config/sheldon
test -L $HOME/.config/sheldon/plugins.toml || ln -f -s $BASEDIR/sheldon.toml $HOME/.config/sheldon/plugins.toml
test -L $HOME/.zsh || ln -f -s $BASEDIR/zsh $HOME/.zsh
test -L $HOME/.zshrc || ln -f -s $BASEDIR/zshrc.zsh $HOME/.zshrc

# If ghostty is installed on the system then setup the config
if (( ${+commands[ghostty]} )); then
  test -L $HOME/Library/Application\ Support/com.mitchellh.ghostty/config || ln -f -s $BASEDIR/ghostty $HOME/Library/Application\ Support/com.mitchellh.ghostty/config
fi

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

echo "Setting up NeoVim"
test -d $HOME/.config/nvim && rm -rf $HOME/.config/nvim
ln -s $BASEDIR/neovim $HOME/.config/nvim

# .gitconfig gets edited by .extra so we won’t symlink it, but copy it
echo "For compatability we chall copy the global gitconfig"
cp $BASEDIR/gitconfig $HOME/.gitconfig

# Source zshrc
echo "And finally, source the .zshrc"
source $HOME/.zshrc
