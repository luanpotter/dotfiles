#!/bin/bash -xe

function not_exists() {
 ! command -v $1 2>&1 >/dev/null
}

# install brew
if not_exists brew; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# install brew packages
brew install \
    gh wget tree the_silver_searcher jq yq fpp htop \
    yt-dlp ffmpeg imagemagick

# java / kotlin
# brew install jenv kotlin
# brew install --cask temurin@21

# dart / flutter
# brew install cocoapods

# TODO: install manually for now
# https://karabiner-elements.pqrs.org/
# aerospace
# vscode, intellij
