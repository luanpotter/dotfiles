#!/bin/bash -xe

sudo pacman -Syu --needed \
    libva-mesa-driver libva-utils \
    vulkan-radeon vulkan-tools \
    mesa mesa-demos
