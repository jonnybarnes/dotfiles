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

# Install zsh and addons
brew install zsh
brew install zsh-autosuggestions
brew install zsh-completions
brew install zsh-history-substring-search
brew install zsh-syntax-highlighting

# Install other useful utilities
brew install ack
brew install age
brew install awscli
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
brew install git-lfs
brew install gnupg
brew install hexyl
brew install imagemagick
brew install lazygit
brew install mcfly
brew install neovim
brew install oh-my-posh
brew install p7zip
brew install pcre
brew install ripgrep
brew install rm-improved
brew install ruby
brew install sheldon
brew install starship
brew install sqlite
brew install thefuck
brew install vivid
brew install wget
brew install xz
brew install zopfli
brew install zoxide

# Remove outdated versions from the Cellar
brew cleanup
