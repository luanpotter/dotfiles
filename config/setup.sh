#!/bin/bash -x
#
## -- determine OS
platform=linux
if [[ "$OSTYPE" == "darwin"* ]]; then
  platform=macos
fi
# --

mkdir -p ~/.config
cd ~/.config/

function setup() {
  dir=$1
  rm -r $dir 2> /dev/null
  ln -s ~/projects/dotfiles/config/$dir $dir
}

# check if linux
if [[ $platform == "linux" ]]; then
  setup awesome
  setup alacritty
  setup rofi
fi
if [[ $platform == "macos" ]]; then
  setup karabiner
  setup aerospace
fi
