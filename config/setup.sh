#!/bin/bash -x

mkdir -p ~/.config
cd ~/.config/

function setup() {
  dir=$1
  rm -r $dir 2> /dev/null
  ln -s ~/projects/dotfiles/config/$dir $dir
}

setup awesome
setup karabiner
setup alacritty
setup rofi
