#!/usr/bin/env bash
# lib/utils.sh — shared helpers for the dotfiles engine

# -- resolve paths
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# -- OS detection
PLATFORM=arch
if [[ "$OSTYPE" == darwin* ]]; then
	PLATFORM=macos
fi

# -- dry-run flag (set by update.sh)
DRY_RUN="${DRY_RUN:-false}"
AUTO_YES="${AUTO_YES:-false}"
FORCE_EXEC="${FORCE_EXEC:-false}"
VERBOSE="${VERBOSE:-false}"

ENV_FILE="$DOTFILES_DIR/env.yaml"

# -- colors
_RED='\033[0;31m'
_GREEN='\033[0;32m'
_YELLOW='\033[0;33m'
_BLUE='\033[0;34m'
_RESET='\033[0m'

log_info() { printf "${_BLUE}[info]${_RESET}  %s\n" "$*" >&2; }
log_ok() { printf "${_GREEN}[ ok ]${_RESET}  %s\n" "$*" >&2; }
log_warn() { printf "${_YELLOW}[warn]${_RESET}  %s\n" "$*" >&2; }
log_error() { printf "${_RED}[err]${_RESET}   %s\n" "$*" >&2; }
log_verbose() { [[ "$VERBOSE" == true ]] && log_ok "$@" || true; }
log_verbose_info() { [[ "$VERBOSE" == true ]] && log_info "$@" || true; }

# -- dry-run guard: prints command if DRY_RUN, otherwise executes it
run_cmd() {
	if [[ "$DRY_RUN" == true ]]; then
		log_info "[dry-run] $*"
	else
		"$@"
	fi
}

# -- env file helpers
# Ensures env.yaml exists with valid YAML structure
_ensure_env() {
	if [[ ! -f "$ENV_FILE" ]]; then
		printf 'modules:\nexec:\n' >"$ENV_FILE"
	fi
}

# Read the exec hash for a module from env.yaml
env_get_hash() {
	local module="$1"
	_ensure_env
	yq -r ".exec.\"$module\" // \"\"" "$ENV_FILE"
}

# Write the exec hash for a module to env.yaml
env_set_hash() {
	local module="$1" hash="$2"
	_ensure_env
	local tmp
	tmp=$(yq -y ".exec.\"$module\" = \"$hash\"" "$ENV_FILE")
	printf '%s\n' "$tmp" >"$ENV_FILE"
}

# -- manifest merge
# Merges os/commons/**/*.yaml + os/<platform>/**/*.yaml, then filters modules
# based on their `default` field and env.yaml overrides. Prints merged YAML to stdout.
merge_manifests() {
	local commons_dir="$DOTFILES_DIR/os/commons"
	local platform_dir="$DOTFILES_DIR/os/$PLATFORM"

	_ensure_env

	# collect all YAML files: commons first, then platform-specific (recursive)
	local -a files=()
	shopt -s nullglob globstar
	for dir in "$commons_dir" "$platform_dir"; do
		[[ -d "$dir" ]] || continue
		for f in "$dir"/**/*.yaml; do
			files+=("$f")
		done
	done
	shopt -u nullglob globstar

	if [[ ${#files[@]} -eq 0 ]]; then
		log_error "no manifest files found"
		return 1
	fi

	log_verbose_info "merging ${#files[@]} manifest(s)"

	# merge all files, then filter modules by platform, enabled/disabled state
	# Resolution: env mismatch → skip; env.yaml override → module default → enabled
	yq -s '
        (reduce .[] as $item ({}; . * ($item | del(.modules)))) +
        {modules: [.[] | (.modules // [])[]]}
    ' "${files[@]}" | yq --argjson env "$(yq '.modules // {}' "$ENV_FILE")" \
		--arg platform "$PLATFORM" '
        .modules = [.modules[] | select(
            if .env != null and .env != $platform then false
            else
                ($env[.name] // null) as $override |
                if $override != null then $override
                elif .default == false then false
                else true
                end
            end
        ) | del(.default, .env)]
    '
}
