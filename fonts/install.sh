#!/bin/bash -xe

sudo bash -O globstar -O nullglob -c 'cp **/*.{ttf,otf} /usr/share/fonts/'
fc-cache
