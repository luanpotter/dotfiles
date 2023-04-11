#!/bin/bash -e

mkdir -p ~/.config
cd ~/.config/

function setup() {
  dir=$1
  rm -r $dir || true
  ln -s ~/projects/dotfiles/config/$dir $dir
}

setup awesome
setup karabiner
setup alacritty
