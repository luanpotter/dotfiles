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

# -- dry-run guard: prints command if DRY_RUN, otherwise executes it
run_cmd() {
	if [[ "$DRY_RUN" == true ]]; then
		log_info "[dry-run] $*"
	else
		"$@"
	fi
}

# -- manifest merge
# Merges os/commons/*.yaml + os/<platform>/*.yaml (minus .disabled entries).
# Prints merged YAML to stdout.
merge_manifests() {
	local commons_dir="$DOTFILES_DIR/os/commons"
	local platform_dir="$DOTFILES_DIR/os/$PLATFORM"
	local disabled_file="$DOTFILES_DIR/.disabled"

	# load disabled list
	local -a disabled=()
	if [[ -f "$disabled_file" ]]; then
		while IFS= read -r line; do
			line="${line%%#*}" # strip comments
			line="${line// /}" # strip spaces
			[[ -n "$line" ]] && disabled+=("$DOTFILES_DIR/$line")
		done <"$disabled_file"
	fi

	# collect files to merge: commons first, then platform-specific (recursive)
	local -a files=()
	shopt -s nullglob globstar
	for dir in "$commons_dir" "$platform_dir"; do
		[[ -d "$dir" ]] || continue
		for f in "$dir"/**/*.yaml; do
			local skip=false
			for d in "${disabled[@]+"${disabled[@]}"}"; do
				if [[ "$f" == "$d" ]]; then
					skip=true
					log_info "skipping disabled manifest: ${f#"$DOTFILES_DIR/"}"
					break
				fi
			done
			[[ "$skip" == false ]] && files+=("$f")
		done
	done
	shopt -u nullglob globstar

	if [[ ${#files[@]} -eq 0 ]]; then
		log_error "no manifest files found"
		return 1
	fi

	log_info "merging ${#files[@]} manifest(s)"
	# python yq (jq wrapper): -s slurps all files into an array, then:
	#   - non-modules keys: deep merge via reduce (last file wins)
	#   - modules: concatenate all arrays
	yq -s '
        (reduce .[] as $item ({}; . * ($item | del(.modules)))) +
        {modules: [.[] | (.modules // [])[]]}
    ' "${files[@]}"
}
