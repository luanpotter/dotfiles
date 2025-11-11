#!/bin/bash -x

## -- determine OS
platform=linux
if [[ "$OSTYPE" == "darwin"* ]]; then
  platform=macos
fi
# --

CONFIG="$HOME/.config"

mkdir -p $CONFIG
cd $CONFIG

function setup() {
  path=$1
  dir=$2
  rm -r "$path/$dir" 2> /dev/null
  ln -s ~/projects/dotfiles/config/$dir "$path/$dir"
}

setup $HOME ".vimrc"

setup $HOME ".warp"
setup $CONFIG "ghostty"
setup $CONFIG "tmux"

if [[ $platform == "linux" ]]; then
  setup $CONFIG awesome
  setup $CONFIG hypr
  setup $CONFIG alacritty
  setup $CONFIG rofi
fi
if [[ $platform == "macos" ]]; then
  setup $CONFIG karabiner
  setup $CONFIG aerospace
fi
