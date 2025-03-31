#!/bin/bash -xe

## -- determine OS
platform=linux
if [[ "$OSTYPE" == "darwin"* ]]; then
  platform=macos
fi
# --

# make sure repo is in the right place
cd "$HOME/projects/dotfiles"

# bin setup
mkdir -p "$HOME/bin"
mkdir -p "$HOME/bin/local_scripts"
SCRIPTS="$HOME/bin/scripts"
rm -f "$SCRIPTS"
ln -s "$HOME/projects/dotfiles/scripts" "$SCRIPTS"

# config setup
( ./config/setup.sh )

# fonts setup
if [[ $platform == "linux" ]]; then
  (cd ./fonts ; ./install.sh)
fi

# git setup
./git-setup.sh
