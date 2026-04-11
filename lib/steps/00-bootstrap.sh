#!/usr/bin/env bash

# step_bootstrap ensures yq, gum, and AUR helper are present,
# then merges manifests and prints the merged YAML to stdout.
step_bootstrap() {
	log_info "bootstrap: ensuring core dependencies"

	if [[ "$PLATFORM" != arch ]]; then
		log_warn "bootstrap: only Arch Linux supported for now, skipping"
		return 0
	fi

	# -- hardcoded pre-YAML bootstrap: install yq + gum so we can parse manifests
	local -a missing=()
	for pkg in yq gum; do
		if ! pacman -Qi "$pkg" &>/dev/null; then
			missing+=("$pkg")
		fi
	done
	if [[ ${#missing[@]} -gt 0 ]]; then
		log_info "bootstrap: installing ${missing[*]}"
		run_cmd sudo pacman -S --needed --noconfirm "${missing[@]}"
	fi

	# -- yq is required for everything beyond bootstrap
	if ! command -v yq &>/dev/null; then
		log_warn "bootstrap: yq not available, cannot merge manifests (dry-run?)"
		return 0
	fi

	# -- merge manifests (now that yq is available)
	local manifest
	manifest="$(merge_manifests)"

	# -- read bootstrap packages from merged manifest
	local -a bootstrap_pkgs=()
	while IFS= read -r pkg; do
		[[ -n "$pkg" ]] && bootstrap_pkgs+=("$pkg")
	done < <(yq -r '.bootstrap // [] | .[]' <<<"$manifest")

	if [[ ${#bootstrap_pkgs[@]} -gt 0 ]]; then
		missing=()
		for pkg in "${bootstrap_pkgs[@]}"; do
			if ! pacman -Qi "$pkg" &>/dev/null; then
				missing+=("$pkg")
			fi
		done
		if [[ ${#missing[@]} -gt 0 ]]; then
			log_info "bootstrap: installing ${missing[*]}"
			run_cmd sudo pacman -S --needed --noconfirm "${missing[@]}"
		else
			log_ok "bootstrap: all packages present"
		fi
	fi

	# -- AUR helper
	local aur_helper
	aur_helper="$(yq -r '.aur_helper // ""' <<<"$manifest")"
	if [[ -n "$aur_helper" ]] && ! command -v "$aur_helper" &>/dev/null; then
		log_info "bootstrap: installing AUR helper '$aur_helper'"
		if [[ "$DRY_RUN" == true ]]; then
			log_info "[dry-run] would install $aur_helper from AUR"
		else
			local tmp
			tmp="$(mktemp -d)"
			git clone "https://aur.archlinux.org/${aur_helper}.git" "$tmp/$aur_helper"
			(cd "$tmp/$aur_helper" && makepkg -si --noconfirm)
			rm -rf "$tmp"
		fi
	elif [[ -n "$aur_helper" ]]; then
		log_ok "bootstrap: $aur_helper already installed"
	fi

	# -- output merged manifest for downstream steps
	echo "$manifest"
}
