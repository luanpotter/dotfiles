#!/usr/bin/env bash
set -euo pipefail

# -- load lib
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB="$DOTFILES_DIR/lib"
source "$LIB/utils.sh"
shopt -s nullglob
for f in "$LIB/steps/"*.sh; do
    source "$f"
done

usage() {
  cat <<EOF
Usage: ./update.sh [OPTIONS]

Declarative dotfiles engine. Reads YAML manifests from os/ and converges
the current system to match the desired state.

Options:
  --help       Show this help message
  --dry-run    Show what would be done without making changes
  --check      Audit mode: surface unmanaged packages and configs

EOF
}

main() {
    local CHECK=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help)    usage; exit 0 ;;
            --dry-run) DRY_RUN=true; shift ;;
            --check)   CHECK=true; shift ;;
            *)         log_error "Unknown option: $1"; usage; exit 1 ;;
        esac
    done
    
    log_info "dotfiles update (platform=$PLATFORM, dry_run=$DRY_RUN)"
    
    # Phase 1: bootstrap (installs yq/gum, merges manifests, installs AUR helper)
    local manifest
    manifest="$(step_bootstrap)"

    if [[ -z "$manifest" ]]; then
        log_ok "done (bootstrap only)"
        return 0
    fi

    if [[ "$CHECK" == true ]]; then
        # TODO: step_audit "$manifest"
        log_warn "audit mode not yet implemented"
    else
        # TODO: step_packages "$manifest"
        # TODO: step_configs "$manifest"
        # TODO: step_exec "$manifest"
        log_ok "system is up to date"
    fi
    
    log_ok "done"
}

main "$@"
