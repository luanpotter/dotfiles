#!/usr/bin/env bash
# Homebrew env (PATH, HOMEBREW_PREFIX, man pages, completions). always run it,
# even if brew is already on PATH: an inherited PATH (e.g. from the tmux
# server) can have it behind /bin, where macOS's bash 3.2 would win.
# shellenv prepends, so source this before anything that must beat brew (nvm)
if [ -x /opt/homebrew/bin/brew ]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
	eval "$(/usr/local/bin/brew shellenv)"
fi
