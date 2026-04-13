#!/usr/bin/env bash

# step_packages reads all install entries from the manifest,
# groups them by package manager, and installs any missing packages
step_packages() {
	local manifest="$1"
	log_verbose_info "packages: collecting install entries"

	# extract unique manager:package pairs from all modules
	local -a all_entries=()
	while IFS= read -r entry; do
		[[ -n "$entry" ]] && all_entries+=("$entry")
	done < <(echo "$manifest" | yq -r '[.modules[].install // [] | .[]] | unique | .[]')

	if [[ ${#all_entries[@]} -eq 0 ]]; then
		log_ok "packages: nothing to install"
		return 0
	fi

	# group by manager
	local -A groups=()
	for entry in "${all_entries[@]}"; do
		local mgr="${entry%%:*}"
		local pkg="${entry#*:}"
		groups[$mgr]+="$pkg "
	done

	# aur helper from manifest (defaults to yay)
	local aur_helper
	aur_helper="$(echo "$manifest" | yq -r '.aur_helper // "yay"')"

	local total_missing=0
	for mgr in "${!groups[@]}"; do
		local -a pkgs=()
		read -ra pkgs <<<"${groups[$mgr]}"
		local count=0

		case "$mgr" in
		pacman) count=$(_install_pacman "${pkgs[@]}") ;;
		aur) count=$(_install_aur "$aur_helper" "${pkgs[@]}") ;;
		brew) count=$(_install_brew "${pkgs[@]}") ;;
		snap) count=$(_install_snap "${pkgs[@]}") ;;
		*) log_warn "packages: unknown manager '$mgr', skipping" ;;
		esac
		total_missing=$((total_missing + count))
	done

	echo "$total_missing"
}

_install_pacman() {
	local -a missing=()
	for pkg in "$@"; do
		pacman -Qi "$pkg" &>/dev/null || missing+=("$pkg")
	done
	if [[ ${#missing[@]} -gt 0 ]]; then
		log_info "packages: pacman installing ${missing[*]}"
		run_cmd sudo pacman -S --needed --noconfirm "${missing[@]}"
	else
		log_verbose "packages: all pacman packages present (${#} total)"
	fi
	echo "${#missing[@]}"
}

_install_aur() {
	local helper="$1"
	shift
	if ! command -v "$helper" &>/dev/null; then
		log_error "packages: AUR helper '$helper' not found"
		return 1
	fi
	local -a missing=()
	for pkg in "$@"; do
		pacman -Qi "$pkg" &>/dev/null || missing+=("$pkg")
	done
	if [[ ${#missing[@]} -gt 0 ]]; then
		log_info "packages: $helper installing ${missing[*]}"
		run_cmd "$helper" -S --needed --noconfirm "${missing[@]}"
	else
		log_verbose "packages: all AUR packages present (${#} total)"
	fi
	echo "${#missing[@]}"
}

_install_snap() {
	if ! command -v snap &>/dev/null; then
		log_error "packages: snap not found"
		return 1
	fi
	local -a missing=()
	for pkg in "$@"; do
		snap list "$pkg" &>/dev/null 2>&1 || missing+=("$pkg")
	done
	if [[ ${#missing[@]} -gt 0 ]]; then
		log_info "packages: snap installing ${missing[*]}"
		for pkg in "${missing[@]}"; do
			run_cmd sudo snap install "$pkg"
		done
	else
		log_verbose "packages: all snap packages present (${#} total)"
	fi
	echo "${#missing[@]}"
}

_install_brew() {
	if ! command -v brew &>/dev/null; then
		log_error "packages: brew not found"
		return 1
	fi
	local -a missing=()
	for pkg in "$@"; do
		brew list "$pkg" &>/dev/null 2>&1 || missing+=("$pkg")
	done
	if [[ ${#missing[@]} -gt 0 ]]; then
		log_info "packages: brew installing ${missing[*]}"
		run_cmd brew install "${missing[@]}"
	else
		log_verbose "packages: all brew packages present (${#} total)"
	fi
	echo "${#missing[@]}"
}
