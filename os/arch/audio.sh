#!/bin/bash -xe

packages=(
  pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
)

sudo pacman -Sy --needed "${packages[@]}"

systemctl --user enable --now pipewire pipewire-pulse wireplumber
