#!/usr/bin/env bash

# step_audit surfaces explicitly installed packages not tracked by any module.
# Shows a gum TUI for triaging unmanaged packages: import into a YAML file,
# uninstall, or skip.
step_audit() {
	local manifest="$1"
	log_info "audit: checking for unmanaged packages"

	# -- collect all declared packages (pacman + aur from modules, plus bootstrap)
	local -A declared=()

	# bootstrap packages
	while IFS= read -r pkg; do
		[[ -n "$pkg" ]] && declared[$pkg]=1
	done < <(echo "$manifest" | yq -r '.bootstrap // [] | .[]')

	# aur helper itself
	local aur_helper
	aur_helper="$(echo "$manifest" | yq -r '.aur_helper // ""')"
	[[ -n "$aur_helper" ]] && declared[$aur_helper]=1

	# module install entries (pacman: and aur: only)
	while IFS= read -r entry; do
		[[ -n "$entry" ]] || continue
		local mgr="${entry%%:*}"
		local pkg="${entry#*:}"
		if [[ "$mgr" == pacman || "$mgr" == aur ]]; then
			declared[$pkg]=1
		fi
	done < <(echo "$manifest" | yq -r '[.modules[].install // [] | .[]] | unique | .[]')

	# -- get all explicitly installed packages from pacman
	local -a installed=()
	while IFS= read -r pkg; do
		installed+=("$pkg")
	done < <(pacman -Qqe)

	# -- diff: find unmanaged
	local -A unmanaged_set=()
	local -a unmanaged_all=()
	for pkg in "${installed[@]}"; do
		if [[ -z "${declared[$pkg]+x}" ]]; then
			unmanaged_set[$pkg]=1
			unmanaged_all+=("$pkg")
		fi
	done

	if [[ ${#unmanaged_all[@]} -eq 0 ]]; then
		log_ok "audit: all ${#installed[@]} explicitly installed packages are tracked"
		return 0
	fi

	# -- build dependency graph within unmanaged set, keep only leaves
	# A "leaf" is an unmanaged package that no other unmanaged package depends on.
	local -A depended_on=()
	for pkg in "${unmanaged_all[@]}"; do
		local deps
		deps=$(pacman -Qi "$pkg" 2>/dev/null | sed -n 's/^Depends On *: *//p')
		[[ "$deps" == "None" ]] && continue
		for dep in $deps; do
			dep="${dep%%[><=]*}" # strip version constraints
			if [[ -n "${unmanaged_set[$dep]+x}" ]]; then
				depended_on[$dep]=1
			fi
		done
	done

	local -a unmanaged=()
	for pkg in "${unmanaged_all[@]}"; do
		if [[ -z "${depended_on[$pkg]+x}" ]]; then
			unmanaged+=("$pkg")
		fi
	done

	log_warn "audit: ${#unmanaged[@]} unmanaged leaf package(s) out of ${#installed[@]} explicitly installed (${#unmanaged_all[@]} total unmanaged)"

	# -- TUI: let user triage unmanaged packages
	if ! command -v gum &>/dev/null; then
		printf '%s\n' "${unmanaged[@]}"
		return 0
	fi

	while true; do
		local action
		action=$(gum choose --header "What would you like to do?" \
			"Import — add packages to a YAML module" \
			"Uninstall — remove packages from system" \
			"List — show all unmanaged packages" \
			"Done") || break

		case "$action" in
		Import*)
			_audit_import "$manifest" "${unmanaged[@]}"
			# re-scan after import
			return 0
			;;
		Uninstall*)
			_audit_uninstall "${unmanaged[@]}"
			return 0
			;;
		List*)
			printf '%s\n' "${unmanaged[@]}" | gum pager
			;;
		Done*) break ;;
		esac
	done
}

_audit_import() {
	local manifest="$1"
	shift
	local -a unmanaged=("$@")

	# pick packages to import
	local -a selected=()
	while IFS= read -r pkg; do
		[[ -n "$pkg" ]] && selected+=("$pkg")
	done < <(printf '%s\n' "${unmanaged[@]}" | gum filter --no-limit --header "Select packages to import")

	if [[ ${#selected[@]} -eq 0 ]]; then
		log_info "audit: no packages selected"
		return 0
	fi

	# pick target YAML file
	local -a yaml_files=()
	shopt -s nullglob globstar
	for f in "$DOTFILES_DIR/os"/**/*.yaml; do
		yaml_files+=("${f#"$DOTFILES_DIR/"}")
	done
	shopt -u nullglob globstar

	local target_file
	target_file=$(printf '%s\n' "${yaml_files[@]}" | gum filter --header "Select target YAML file")
	[[ -z "$target_file" ]] && return 0

	# pick existing module or create new
	local -a module_names=()
	while IFS= read -r name; do
		[[ -n "$name" ]] && module_names+=("$name")
	done < <(yq -r '.modules[].name // empty' "$DOTFILES_DIR/$target_file")
	module_names+=("[new module]")

	local target_module
	target_module=$(printf '%s\n' "${module_names[@]}" | gum filter --header "Select module")
	[[ -z "$target_module" ]] && return 0

	if [[ "$target_module" == "[new module]" ]]; then
		target_module=$(gum input --placeholder "module name")
		[[ -z "$target_module" ]] && return 0
		# detect manager: if package is foreign (AUR), use aur:, else pacman:
		local -a entries=()
		for pkg in "${selected[@]}"; do
			if pacman -Qm "$pkg" &>/dev/null; then
				entries+=("aur:$pkg")
			else
				entries+=("pacman:$pkg")
			fi
		done
		# append new module
		local install_yaml
		install_yaml=$(printf '    - %s\n' "${entries[@]}")
		printf '\n  - name: %s\n    install:\n%s\n' "$target_module" "$install_yaml" \
			>>"$DOTFILES_DIR/$target_file"
		log_ok "audit: created module '$target_module' in $target_file with ${#selected[@]} package(s)"
	else
		# append to existing module's install list using sed to preserve formatting
		local file="$DOTFILES_DIR/$target_file"
		for pkg in "${selected[@]}"; do
			local entry
			if pacman -Qm "$pkg" &>/dev/null; then
				entry="aur:$pkg"
			else
				entry="pacman:$pkg"
			fi
			# find the install block for this module and append after the last entry
			# strategy: find "name: <module>" line, then find the next "install:" line,
			# then find the last "- " line in that block, and insert after it
			local name_line
			name_line=$(grep -n "name: $target_module" "$file" | head -1 | cut -d: -f1)
			if [[ -z "$name_line" ]]; then
				log_warn "audit: could not find module '$target_module' in $target_file"
				return 1
			fi
			local install_line
			install_line=$(tail -n +"$name_line" "$file" | grep -n 'install:' | head -1 | cut -d: -f1)
			if [[ -z "$install_line" ]]; then
				# no install block yet — add one after the name line
				sed -i "${name_line}a\\    install:\\n      - $entry" "$file"
			else
				install_line=$((name_line + install_line - 1))
				# find the last "- " line in this install block
				local last_entry_line=$install_line
				local i=$((install_line + 1))
				while IFS= read -r line; do
					if [[ "$line" =~ ^[[:space:]]*-\  ]]; then
						last_entry_line=$i
					else
						break
					fi
					((i++))
				done < <(tail -n +"$((install_line + 1))" "$file")
				sed -i "${last_entry_line}a\\      - $entry" "$file"
			fi
		done
		log_ok "audit: added ${#selected[@]} package(s) to module '$target_module' in $target_file"
	fi
}

_audit_uninstall() {
	local -a unmanaged=("$@")

	local -a selected=()
	while IFS= read -r pkg; do
		[[ -n "$pkg" ]] && selected+=("$pkg")
	done < <(printf '%s\n' "${unmanaged[@]}" | gum filter --no-limit --header "Select packages to uninstall")

	if [[ ${#selected[@]} -eq 0 ]]; then
		log_info "audit: no packages selected"
		return 0
	fi

	log_warn "audit: will uninstall ${selected[*]}"
	if gum confirm "Uninstall ${#selected[@]} package(s)?"; then
		sudo pacman -Rns --noconfirm "${selected[@]}"
		log_ok "audit: uninstalled ${#selected[@]} package(s)"
	else
		log_info "audit: cancelled"
	fi
}
