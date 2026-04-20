#!/usr/bin/env zsh

# Check brew is installed first
if ! (( $+commands[brew] ))
then
    echo "Homebrew not installed yet"
    exit 1
fi

# update brew, and upgrade already installed formulae
brew update
brew upgrade

# Install GNU coreutils, (macOS ships with outdated versions)
brew install coreutils

# Install more system utilities
brew install moreutils findutils
# Install GNU `sed`
brew install gnu-sed --with-default-names

# Install more recent versions of some macOS tools.
brew install vim
brew install curl
brew install grep
brew install openssh
brew install rsync
brew install zsh

# Install other useful utilities
brew install ack
brew install age
brew install awscli
brew install b3sum
brew install bat
brew install oven-sh/bun/bun
brew install diff-so-fancy
brew install eza
brew install fd
brew install ffmpeg
brew install fnm
brew install fzf
brew install gh
brew install git
brew install git-delta
brew install git-lfs
brew install gnupg
brew install hexyl
brew install lazygit
brew install mcfly
brew install neovim
brew install p7zip
brew install pcre
brew install ripgrep
brew install rm-improved
brew install ruby
brew install sheldon
brew install sqlite
brew install thefuck
brew install tmux
brew install uv
brew install vivid
brew install wget
brew install xz
brew install zopfli
brew install zoxide

# Install some casks
brew install --cask 1password-cli
brew install --cask airbuddy
brew install --cask claude-code
brew install --cask ngrok
brew install --cask silentknight
brew install --cask sublime-text

# Remove outdated versions from the Cellar
brew cleanup
