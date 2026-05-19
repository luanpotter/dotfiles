#!/usr/bin/env bash
set -euo pipefail

# -- load lib
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB="$DOTFILES_DIR/lib"
# shellcheck source=lib/utils.sh
source "$LIB/utils.sh"
shopt -s nullglob
# shellcheck source=lib/steps/exec.sh
for f in "$LIB/steps/"*.sh; do
	source "$f"
done

usage() {
	cat <<EOF
Usage: ./update.sh [OPTIONS]

Declarative dotfiles engine. Reads YAML manifests from os/ and converges
the current system to match the desired state.

Options:
  --help              Show this help message
  --print-platform    Print DOTFILES_PLATFORM and os-release context, then exit
  --dry-run           Show what would be done without making changes
  --check             Audit mode: surface unmanaged packages and configs
  --manage            Toggle modules on/off via TUI
  --yes, -y           Auto-confirm exec blocks (no interactive prompts)
  --force             Re-run all exec blocks regardless of hash
  --verbose, -v       Verbose output (show per-item details)

EOF
}

is_running_as_root() {
	[[ "${EUID:-$(id -u)}" -eq 0 ]]
}

prime_sudo() {
	if [[ "$DRY_RUN" == true ]] || is_running_as_root; then
		return 0
	fi
	if [[ "$DOTFILES_PLATFORM" == "macos" ]]; then
		# On macOS, brew flows don't need sudo
		return 0
	fi
	sudo -v
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
		--print-platform)
			dotfiles_print_platform
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

	prime_sudo
	log_info "dotfiles update (dotfiles_platform=$DOTFILES_PLATFORM, dry_run=$DRY_RUN)"

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
		step_pull
		step_upgrade

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
