#!/bin/bash -xe

packages=(
    wayland wayland-protocols # base
    libinput # input
    polkit uwsm # session
    xdg-desktop-portal xdg-desktop-portal-wlr # portals for screen sharing, file pickers
    xorg-xwayland # xorg compat
    hyprland # hyprland
    pipewire wireplumber # audio stack
    # plugins
    waybar # top bar
)

sudo pacman -Sy --needed "${packages[@]}"
