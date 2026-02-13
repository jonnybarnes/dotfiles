#!/usr/bin/env zsh

# Current dir
BASEDIR=$(pwd)

# ln the various files
echo "Sym-linking the various config files"
test -L $HOME/.gitignore || ln -f -s $BASEDIR/gitignore $HOME/.gitignore
test -L $HOME/.hushlogin || ln -f -s $BASEDIR/hushlogin $HOME/.hushlogin
test -L $HOME/.tmux.conf || ln -f -s $BASEDIR/tmux $HOME/.tmux.conf
test -d $HOME/.config/sheldon || mkdir $HOME/.config/sheldon
test -L $HOME/.config/sheldon/plugins.toml || ln -f -s $BASEDIR/sheldon.toml $HOME/.config/sheldon/plugins.toml
test -L $HOME/.zsh || ln -f -s $BASEDIR/zsh $HOME/.zsh
test -L $HOME/.zshrc || ln -f -s $BASEDIR/zshrc.zsh $HOME/.zshrc
test -d $HOME/.config/delta || mkdir $HOME/.config/delta
test -L $HOME/.config/delta/themes.gitconfig || ln -f -s $BASEDIR/delta-themes.gitconfig $HOME/.config/delta/themes.gitconfig

# If ghostty is installed on the system then setup the config
if (( ${+commands[ghostty]} )); then
  test -d $HOME/.config/ghostty || mkdir $HOME/.config/ghostty
  test -L $HOME/.config/ghostty/config || ln -f -s $BASEDIR/ghostty/config $HOME/.config/ghostty/config
  test -d $HOME/.config/ghostty/themes || mkdir $HOME/.config/ghostty/themes
  test -L $HOME/.config/ghostty/themes/tangere-dark.conf || ln -f -s $BASEDIR/ghostty/themes/tangere-dark $HOME/.config/ghostty/themes/tangere-dark.conf
  test -L $HOME/.config/ghostty/themes/tangere-light.conf || ln -f -s $BASEDIR/ghostty/themes/tangere-light $HOME/.config/ghostty/themes/tangere-light.conf
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

echo "Setting up NeoVim"
test -d $HOME/.config/nvim && rm -rf $HOME/.config/nvim
ln -s $BASEDIR/neovim $HOME/.config/nvim

# .gitconfig gets edited by .extra so we won't symlink it, but copy it
echo "For compatibility we shall copy the global gitconfig"
cp $BASEDIR/gitconfig $HOME/.gitconfig

# Copy the progs into the local bin dir
rsync -av --chmod=+x $BASEDIR/bin/ $HOME/.local/bin/

# Source zshrc
echo "And finally, source the .zshrc"
source $HOME/.zshrc
