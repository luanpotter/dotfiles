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
  --manage     Toggle modules on/off via TUI
  --yes, -y    Auto-confirm exec blocks (no interactive prompts)
  --force      Re-run all exec blocks regardless of hash
  --verbose, -v Verbose output (show per-item details)

EOF
}

main() {
	local CHECK=false
	local MANAGE=false

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--help)
			usage
			exit 0
			;;
		--dry-run)
			DRY_RUN=true
			shift
			;;
		--check)
			CHECK=true
			shift
			;;
		--manage)
			MANAGE=true
			shift
			;;
		--yes | -y)
			AUTO_YES=true
			shift
			;;
		--force)
			FORCE_EXEC=true
			shift
			;;
		--verbose | -v)
			VERBOSE=true
			shift
			;;
		*)
			log_error "Unknown option: $1"
			usage
			exit 1
			;;
		esac
	done

	log_info "dotfiles update (platform=$PLATFORM, dry_run=$DRY_RUN)"

	# Phase 0: git pull if clean on master
	local branch
	branch="$(git -C "$DOTFILES_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
	if [[ "$branch" == "master" ]] && git -C "$DOTFILES_DIR" diff --quiet 2>/dev/null &&
		git -C "$DOTFILES_DIR" diff --cached --quiet 2>/dev/null; then
		log_info "pulling latest from master"
		run_cmd git -C "$DOTFILES_DIR" pull --ff-only
	else
		log_warn "running with local changes (branch=$branch)"
	fi

	# Phase 0.5: system upgrade
	log_info "upgrading system packages"
	run_cmd sudo pacman -Syu --noconfirm

	# Phase 1: bootstrap (installs yq/gum, merges manifests, installs AUR helper)
	local manifest
	manifest="$(step_bootstrap)"

	if [[ -z "$manifest" ]]; then
		log_ok "done (bootstrap only)"
		return 0
	fi

	if [[ "$MANAGE" == true ]]; then
		step_manage "$manifest"
		return 0
	elif [[ "$CHECK" == true ]]; then
		step_audit "$manifest"
	else
		local pending=0
		local count
		count=$(step_packages "$manifest")
		pending=$((pending + count))
		count=$(step_configs "$manifest")
		pending=$((pending + count))
		count=$(step_exec "$manifest")
		pending=$((pending + count))

		if [[ "$DRY_RUN" == true && $pending -gt 0 ]]; then
			log_warn "update needed, would update $pending item(s)"
		fi
	fi

	log_ok "done"
}

main "$@"
