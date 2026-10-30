#!/usr/bin/env bash

# GNU sed for macOS: make `sed` behave like Linux/GNU sed.
# Requires: brew install gnu-sed, and brew.sh sourced first

# Prefer GNU sed's unprefixed binaries
if command -v brew >/dev/null 2>&1; then
	HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix 2>/dev/null)}"
	if [ -n "$HOMEBREW_PREFIX" ] && [ -x "$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin/sed" ]; then
		PATH="$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin:$PATH"
		export PATH
	fi
fi

# Optional: fail loudly if GNU sed is not actually active
sed --version >/dev/null 2>&1 || {
	echo "warning: GNU sed is not active. Run: brew install gnu-sed" >&2
}
