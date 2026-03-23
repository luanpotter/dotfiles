#!/usr/bin/env bash
set -xe

sudo bash -O globstar -O nullglob -c 'cp **/*.{ttf,otf} /usr/share/fonts/'
fc-cache
