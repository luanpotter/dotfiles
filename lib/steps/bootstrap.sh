#!/usr/bin/env bash

# Install the underlying system package / binary for a manager if missing.
# Native managers are verified but need no separate tooling.
# Portable managers (brew, snap, flatpak) need platform-specific install.
_bootstrap_manager_tooling() {
	local mgr="$1"

	case "$mgr" in
	pacman | apt)
		if ! check_cmd "$mgr"; then
			log_warn "bootstrap: native manager '$mgr' not found on system"
		fi
		return 0
		;;
	brew)
		if check_cmd brew; then
			return 0
		fi
		log_error "bootstrap: Homebrew not found; install from https://brew.sh"
		return 1
		;;
	snap)
		check_cmd snap && return 0
		case "$DOTFILES_PLATFORM" in
		arch)
			log_info "bootstrap: installing snapd"
			run_cmd sudo pacman -S --needed --noconfirm snapd >&2 || return 1
			;;
		debian)
			log_info "bootstrap: installing snapd"
			run_cmd sudo apt-get update >&2 || return 1
			run_cmd sudo apt-get install -y snapd >&2 || return 1
			;;
		*)
			log_warn "bootstrap: don't know how to install snapd on $DOTFILES_PLATFORM"
			;;
		esac
		return 0
		;;
	*)
		log_warn "bootstrap: no tooling recipe for manager '$mgr'"
		return 0
		;;
	esac
}

# step_bootstrap ensures yq and platform package managers are ready,
# then merges manifests and prints the merged YAML to stdout.
step_bootstrap() {
	log_info "bootstrap: ensuring core dependencies"

	# -- 1. core tooling per platform
	case "$DOTFILES_PLATFORM" in
	arch)
		local -a missing=()
		for pkg in yq gum; do
			if ! pacman -Qi "$pkg" &>/dev/null; then
				missing+=("$pkg")
			fi
		done
		if [[ ${#missing[@]} -gt 0 ]]; then
			log_info "bootstrap: installing ${missing[*]}"
			run_cmd sudo pacman -S --needed --noconfirm "${missing[@]}" >&2 || return 1
		fi
		;;
	debian)
		local -a missing=()
		dpkg -s yq &>/dev/null || missing+=(yq)
		if [[ ${#missing[@]} -gt 0 ]]; then
			log_info "bootstrap: installing ${missing[*]}"
			run_cmd sudo apt-get update >&2 || return 1
			run_cmd sudo apt-get install -y "${missing[@]}" >&2 || return 1
		fi
		;;
	macos)
		if ! check_cmd brew; then
			log_error "bootstrap: Homebrew not found; install from https://brew.sh"
			return 1
		fi
		local -a missing=()
		brew list python-yq &>/dev/null 2>&1 || missing+=(python-yq)
		brew list gum &>/dev/null 2>&1 || missing+=(gum)
		if [[ ${#missing[@]} -gt 0 ]]; then
			log_info "bootstrap: brewing ${missing[*]}"
			run_cmd brew install "${missing[@]}" >&2 || return 1
		fi
		;;
	*)
		log_warn "bootstrap: platform '$DOTFILES_PLATFORM' has no bootstrap recipe; ensure yq is installed"
		;;
	esac

	if ! check_cmd yq; then
		log_warn "bootstrap: yq not available, cannot merge manifests (dry-run?)"
		return 0
	fi

	# -- 2. read manifest once, before manager tooling
	local manifest
	manifest="$(merge_manifests)"

	# -- 3. manager tooling bootstrap
	local mgr_list="${DOTFILES_MANAGERS_BY_PLATFORM[$DOTFILES_PLATFORM]:-}"
	for mgr in $mgr_list; do
		_bootstrap_manager_tooling "$mgr" || return 1
	done

	# -- 4. manifest bootstrap packages (platform-specific install)
	local -a bootstrap_pkgs=()
	while IFS= read -r pkg; do
		[[ -n "$pkg" ]] && bootstrap_pkgs+=("$pkg")
	done < <(yq -r '.bootstrap // [] | .[]' <<<"$manifest")

	case "$DOTFILES_PLATFORM" in
	arch)
		if [[ ${#bootstrap_pkgs[@]} -gt 0 ]]; then
			local -a missing=()
			for pkg in "${bootstrap_pkgs[@]}"; do
				if ! pacman -Qi "$pkg" &>/dev/null; then
					missing+=("$pkg")
				fi
			done
			if [[ ${#missing[@]} -gt 0 ]]; then
				log_info "bootstrap: installing ${missing[*]}"
				run_cmd sudo pacman -S --needed --noconfirm "${missing[@]}" >&2 || return 1
			else
				log_verbose "bootstrap: all packages present"
			fi
		fi
		;;
	debian)
		if [[ ${#bootstrap_pkgs[@]} -gt 0 ]]; then
			local -a missing=()
			for pkg in "${bootstrap_pkgs[@]}"; do
				dpkg -s "$pkg" &>/dev/null || missing+=("$pkg")
			done
			if [[ ${#missing[@]} -gt 0 ]]; then
				log_info "bootstrap: installing ${missing[*]}"
				run_cmd sudo apt-get update >&2 || return 1
				run_cmd sudo apt-get install -y "${missing[@]}" >&2 || return 1
			else
				log_verbose "bootstrap: all packages present"
			fi
		fi
		;;
	esac

	echo "$manifest"
}
