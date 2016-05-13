# dotfiles

Here’s my dotfiles, inspired by people like Mathias. See his dotfiles at
[`https://github.com/mathias/dotfiles`](https://github.com/mathias/dotfiles).

The idea I’m currently going down is to create a symlink from `$HOME` to this
directory. There is one exception to this, the `.gitconfig` file. This derives
from not wanting anyone to accidentally commiting as me to git, that would
however require people to use this repo, unlikely. So my git credentials are
stored in a `.extra` file which gets sourced. This then calls the relavent git
command, which causes git to edit `$HOME/.gitconfig`. If that file was a symlink
to this repo, then the repo would see the file as edited and the repo would then
be in a dirty state, permanently.

## Usage

First clone the repo.

As mentioned above my git credentials are stored in an untracked file:
`$HOME/.extra`. This must be manually created, mine looks like:

```
# Git credentials
GIT_AUTHOR_NAME="Jonny Barnes"
GIT_COMMITER_NAME="$GIT_AUTHOR_NAME"
git config --global user.name "$GIT_AUTHOR_NAME"
GIT_AUTHOR_EMAIL="jonny@jonnybarnes.uk"
GIT_COMMITER_EMAIL="$GIT_AUTHOR_EMAIL"
git config --global user.email "$GIT_AUTHOR_EMAIL"
```

Run `./boostrap.sh`, this will create all the necessary symlinks, then source
`.zshrc`. This is a **destructive** process, so backup your dotfiles first.
