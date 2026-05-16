#!/usr/bin/env bash

# step_bootstrap ensures yq and platform package managers are ready,
# then merges manifests and prints the merged YAML to stdout.
step_bootstrap() {
	log_info "bootstrap: ensuring core dependencies"

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
	*)
		log_warn "bootstrap: platform '$DOTFILES_PLATFORM' has no bootstrap recipe; ensure yq is installed"
		;;
	esac

	if ! command -v yq &>/dev/null; then
		log_warn "bootstrap: yq not available, cannot merge manifests (dry-run?)"
		return 0
	fi

	local manifest
	manifest="$(merge_manifests)"

	# -- read bootstrap packages from merged manifest
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

		local aur_helper
		aur_helper="$(yq -r '.aur_helper // ""' <<<"$manifest")"
		if [[ -n "$aur_helper" ]] && ! command -v "$aur_helper" &>/dev/null; then
			log_info "bootstrap: installing AUR helper '$aur_helper'"
			if [[ "$DRY_RUN" == true ]]; then
				log_info "[dry-run] would install $aur_helper from AUR"
			else
				local tmp
				tmp="$(mktemp -d)"
				git clone "https://aur.archlinux.org/${aur_helper}.git" "$tmp/$aur_helper" >&2
				(cd "$tmp/$aur_helper" && makepkg -si --noconfirm) >&2
				rm -rf "$tmp"
			fi
		elif [[ -n "$aur_helper" ]]; then
			log_verbose "bootstrap: $aur_helper already installed"
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
