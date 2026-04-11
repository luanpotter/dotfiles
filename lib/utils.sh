#!/usr/bin/env bash
# lib/utils.sh — shared helpers for the dotfiles engine

# -- resolve paths
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# -- OS detection
PLATFORM=linux
if [[ "$OSTYPE" == darwin* ]]; then
    PLATFORM=macos
fi

# -- dry-run flag (set by update.sh)
DRY_RUN="${DRY_RUN:-false}"

# -- colors
_RED='\033[0;31m'
_GREEN='\033[0;32m'
_YELLOW='\033[0;33m'
_BLUE='\033[0;34m'
_RESET='\033[0m'

log_info()  { printf "${_BLUE}[info]${_RESET}  %s\n" "$*"; }
log_ok()    { printf "${_GREEN}[ ok ]${_RESET}  %s\n" "$*"; }
log_warn()  { printf "${_YELLOW}[warn]${_RESET}  %s\n" "$*" >&2; }
log_error() { printf "${_RED}[err]${_RESET}   %s\n" "$*" >&2; }

# -- dry-run guard: prints command if DRY_RUN, otherwise executes it
run_cmd() {
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[dry-run] $*"
    else
        "$@"
    fi
}
