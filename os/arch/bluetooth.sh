#!/usr/bin/env bash
set -xe

packages=(
    bluez bluez-utils
)

sudo pacman -Sy --needed "${packages[@]}"

systemctl --user enable --now pipewire pipewire-pulse wireplumber
