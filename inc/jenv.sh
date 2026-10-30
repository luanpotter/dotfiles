#!/usr/bin/env bash
# jenv's shims pick the JDK on every call; they only need to be on PATH.
# skips `jenv init`, whose per-shell rehash is slow. so `jenv shell` is
# unavailable, and after adding a JDK run: jenv rehash
export PATH="$HOME/.jenv/shims:$PATH"
