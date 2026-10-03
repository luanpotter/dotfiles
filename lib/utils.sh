#!/usr/bin/env bash
# lib/utils.sh — shared helpers for the dotfiles engine

# -- resolve paths
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# -- OS detection (lib/detect.sh)
source "$DOTFILES_DIR/lib/detect.sh"

# -- dry-run flag (set by update.sh)
DRY_RUN="${DRY_RUN:-false}"
AUTO_YES="${AUTO_YES:-false}"
FORCE_EXEC="${FORCE_EXEC:-false}"
VERBOSE="${VERBOSE:-false}"

# local state (module overrides, exec hashes)
ENV_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/env.yaml"

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
log_verbose() { if [[ "$VERBOSE" == true ]]; then log_ok "$@"; fi; }
log_verbose_info() { if [[ "$VERBOSE" == true ]]; then log_info "$@"; fi; }

# -- dry-run guard: prints command if DRY_RUN, otherwise executes it
run_cmd() {
	if [[ "$DRY_RUN" == true ]]; then
		log_info "[dry-run] $*"
	else
		"$@"
	fi
}

# -- interrupt handling
# update.sh traps INT with on_interrupt: one message, exit 130.
on_interrupt() {
	trap - INT
	printf '\n' >&2
	log_warn "interrupted"
	exit 130
}

# Ends the whole run from anywhere, including $(...) subshells (which don't
# inherit traps): $$ is always the main script, so its trap fires once.
abort_run() {
	kill -INT "$$"
	exit 130
}

# -- ui: plain prompts via read, pickers via fzf
# Prompts read from /dev/tty so they work inside pipes and $(...).

# ui_confirm PROMPT [y|n] - y/n question; second arg is the Enter default
ui_confirm() {
	local prompt="$1" default="${2:-n}" hint="[y/N]" reply
	if [[ "$default" == y ]]; then
		hint="[Y/n]"
	fi
	read -rp "$prompt $hint " reply </dev/tty
	reply="${reply:-$default}"
	[[ "$reply" == [yY]* ]]
}

# ui_input PROMPT - prints one line of free text
ui_input() {
	local reply
	read -rp "$1: " reply </dev/tty
	printf '%s\n' "$reply"
}

# exit code for "Esc: go back one step" in pickers
UI_BACK=3

# _ui_fzf ARGS... - fzf with shared styling; items on stdin, picks on stdout.
# fzf owns the terminal, so Ctrl+C/Esc reach it as keys, not SIGINT:
# Ctrl+C exits 130, Esc exits $UI_BACK (needs fzf >= 0.38 for become).
# Tab toggles in place (fzf's default also moves the cursor down).
_ui_fzf() {
	fzf --height=40% --layout=reverse --border \
		--bind "tab:toggle,btab:toggle,esc:become(exit $UI_BACK)" "$@"
}

# ui_choose HEADER [fzf args...] - pick from stdin.
# Returns $UI_BACK on Esc; Ctrl+C aborts the run.
ui_choose() {
	local header="$1"
	shift
	# keep the items so the picker can reopen after an Enter with no match (exit 1)
	local items rc
	items=$(cat)
	while true; do
		rc=0
		printf '%s\n' "$items" | _ui_fzf --header "$header · Esc: back" "$@" || rc=$?
		case "$rc" in
		1) continue ;;
		130) abort_run ;;
		*) return "$rc" ;;
		esac
	done
}

# ui_pager - page stdin
ui_pager() {
	"${PAGER:-less}"
}

# -- command presence check
# Returns 0 if the given command exists in PATH.
check_cmd() {
	command -v "$1" &>/dev/null
}

declare -A DOTFILES_MANAGERS_BY_PLATFORM=(
	[arch]='pacman'
	[debian]='apt snap'
	[macos]='brew'
	[default]=''
)

# Returns 0 if install lines using this manager should run on DOTFILES_PLATFORM.
dotfiles_manager_supported() {
	local mgr="$1"
	local list="${DOTFILES_MANAGERS_BY_PLATFORM[$DOTFILES_PLATFORM]:-}"
	[[ -z "$list" ]] && list="${DOTFILES_MANAGERS_BY_PLATFORM[default]}"

	local -a allowed=()
	read -ra allowed <<<"$list"
	local m
	for m in "${allowed[@]}"; do
		[[ "$m" == "$mgr" ]] && return 0
	done
	return 1
}

# -- env file helpers
# Ensures env.yaml exists with valid YAML structure
_ensure_env() {
	if [[ ! -f "$ENV_FILE" ]]; then
		mkdir -p "$(dirname "$ENV_FILE")"
		env_write $'modules:\nexec:'
	fi
}

# atomic replace of env.yaml, avoid concurrency or interruption corruptions.
env_write() {
	local content="$1"
	if [[ -z "$content" ]]; then
		log_error "env: refusing to write empty env.yaml"
		return 1
	fi
	local tmp
	tmp=$(mktemp "$ENV_FILE.XXXXXX")
	if ! printf '%s\n' "$content" >"$tmp" || ! mv -f "$tmp" "$ENV_FILE"; then
		rm -f "$tmp"
		log_error "env: failed to write env.yaml"
		return 1
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
	env_write "$tmp"
}

# -- manifest merge
# Merges os/commons/**/*.yaml + os/<DOTFILES_PLATFORM>/**/*.yaml, then filters modules
# based on their `default` field and env.yaml overrides. Prints merged YAML to stdout.
merge_manifests() {
	local commons_dir="$DOTFILES_DIR/os/commons"
	local platform_dir="$DOTFILES_DIR/os/$DOTFILES_PLATFORM"

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
	local filter_merge filter_select
	read -r -d '' filter_merge <<'YQ'
(reduce .[] as $item ({}; . * ($item | del(.modules)))) +
{modules: [.[] | (.modules // [])[]]}
YQ
	read -r -d '' filter_select <<'YQ'
.modules = [.modules[] | select(
    if .env != null and .env != $platform then false
    else
        .name as $n |
        if ($env | has($n)) then $env[$n]
        elif .default == false then false
        else true
        end
    end
) | del(.default, .env)]
YQ
	yq -s "$filter_merge" "${files[@]}" | yq --argjson env "$(yq '.modules // {}' "$ENV_FILE")" \
		--arg platform "$DOTFILES_PLATFORM" "$filter_select"
}
