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

## Auto switch between light and dark mode

To switch between dark and light mode automatically, we use a helper lib.

Clone it from `https://github.com/bouk/dark-mode-notify` then run `make` and `make install`.

Then make a script to run is automatically, put the plist where your system can find it: `~/Library/LaunchAgents/ke.bou.dark-mode-notify.plist` with the following content:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>ke.bou.dark-mode-notify</string>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/Users/jonny/.local/var/log/dark-mode-notify-stderr.log</string>
    <key>StandardOutPath</key>
    <string>/Users/jonny/.local/var/log/dark-mode-notify-stdout.log</string>
    <key>ProgramArguments</key>
    <array>
       <string>/usr/local/bin/dark-mode-notify</string>
       <string>/Users/jonny/git/dotfiles/zsh/dark-mode-notify.zsh</string>
    </array>
</dict>
</plist>
```

Make the log file and script file point to the right location. For clarity `dark-mode-notify.zsh` is in this repo.

