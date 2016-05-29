#!/usr/bin/env zsh

# Install Homebrew stuff
brew tap homebrew/dupes
brew tap homebrew/php
brew tap homebrew/services
brew tap tldr-pages/tldr

# update brew, and upgrade already installed formulae
brew update
brew upgrade

# Install GNU coreutils, (OS X ships with outdated versions)
brew install coreutils
ln -s /usr/local/bin/gsha256sum /usr/local/bin/sha256sum

# Install more system utilities
brew install moreutils findutils
# Install GNU `sed`
brew install gnu-sed --with-default-names

# Install wget with IRI support
brew install wget --with-iri

# Install more recent versions of some OS X tools.
brew install vim --override-system-vi
brew install homebrew/dupes/grep
brew install homebrew/dupes/openssh

# Install zsh and addons
brew install zsh
brew install zsh-completions
brew install zsh-syntax-highlighting

# Install other useful utilities
brew install ack
brew install git
brew install git-lfs
brew install diff-so-fancy
brew install imagemagick --with-webp
brew install lua
brew install lynx
brew install p7zip
brew install xz
brew install zopfli

# Remove outdated versions from the Cellar
brew cleanup
