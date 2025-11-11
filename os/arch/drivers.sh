#!/bin/bash -xe

packages=(
    libva-mesa-driver libva-utils
    vulkan-radeon vulkan-tools
    mesa mesa-demos
)

sudo pacman -Sy --needed "${packages[@]}"
