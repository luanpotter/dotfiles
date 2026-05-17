#!/usr/bin/env bash

_audit_install_entry_for_pkg() {
	local pkg="$1"
	if pacman -Qm "$pkg" &>/dev/null; then
		printf 'aur:%s\n' "$pkg"
	else
		printf 'pacman:%s\n' "$pkg"
	fi
}

# List existing module names; safe when `modules:` is absent or null (yq 3/jq compat).
_audit_yaml_module_names_get() {
	local file="$1"
	yq -r '(.modules // [])[] | .name // empty' "$file" 2>/dev/null || true
}

_audit_yaml_has_list_module_entry() {
	# Match `modules:` lists that use `- name:` (same as other os/**/*.yaml files).
	grep -qE '^[[:space:]]*-[[:space:]]+name:[[:space:]]' "$1" 2>/dev/null
}

# Append one module — matches spacing in e.g. os/arch/core.yaml: no gap after `modules:`,
# one blank line before each later `- name:`.
_audit_append_module_block() {
	local target_rel="$1"
	local module_name="$2"
	shift 2
	local -a entries=("$@")
	local file="$DOTFILES_DIR/$target_rel"
	local install_yaml="" e
	local nl_before=$''

	for e in "${entries[@]}"; do
		install_yaml+="      - $e"$'\n'
	done
	if _audit_yaml_has_list_module_entry "$file"; then
		nl_before=$'\n'
	fi
	printf '%s  - name: %s\n    install:\n%s' "$nl_before" "$module_name" "$install_yaml" >>"$file"
}

# _audit_pacman implements the Arch audit backend.
# Surfaces explicitly installed packages not tracked by any module.
_audit_pacman() {
	local manifest="$1"

	# -- collect all declared packages (pacman + aur from modules, plus bootstrap)
	local -A declared=()

	# bootstrap packages
	while IFS= read -r pkg; do
		[[ -n "$pkg" ]] && declared[$pkg]=1
	done < <(printf '%s\n' "$manifest" | yq -r '.bootstrap // [] | .[]')

	# aur helper itself
	local aur_helper
	aur_helper="$(printf '%s\n' "$manifest" | yq -r '.aur_helper // ""')"
	[[ -n "$aur_helper" ]] && declared[$aur_helper]=1

	# module install entries (pacman: and aur: only)
	while IFS= read -r entry; do
		[[ -n "$entry" ]] || continue
		local mgr="${entry%%:*}"
		local pkg="${entry#*:}"
		if [[ "$mgr" == pacman || "$mgr" == aur ]]; then
			declared[$pkg]=1
		fi
	done < <(printf '%s\n' "$manifest" | yq -r '[(.modules // [])[] | (.install // [])[]] | unique | .[]')

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
			_audit_import "${unmanaged[@]}"
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

# step_audit dispatches to the platform-specific audit backend.
# Unsupported platforms print one line and exit 0.
step_audit() {
	local manifest="$1"
	log_info "audit: checking for unmanaged packages"

	case "$DOTFILES_PLATFORM" in
	arch)
		_audit_pacman "$manifest"
		;;
	*)
		log_info "audit: native backend not implemented for '$DOTFILES_PLATFORM'"
		return 0
		;;
	esac
}

_audit_import() {
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

	# pick target YAML file (first choice creates os/<path> stubbed as `modules:`)
	local -a yaml_choices=("[+] Create new YAML under os/")
	shopt -s nullglob globstar
	local f
	for f in "$DOTFILES_DIR/os"/**/*.yaml; do
		yaml_choices+=("${f#"$DOTFILES_DIR/"}")
	done
	shopt -u nullglob globstar

	local target_pick target_file=""
	target_pick=$(printf '%s\n' "${yaml_choices[@]}" | gum filter --header "Select target YAML file")
	[[ -z "$target_pick" ]] && return 0

	if [[ "$target_pick" == "[+] Create new YAML under os/" ]]; then
		local rel
		if ! rel=$(gum input --placeholder "relative path under os/, e.g. arch/misc.yaml"); then
			return 0
		fi
		rel="${rel/#\//}"
		rel="${rel#"os/"}"
		[[ -z "$rel" ]] && return 0
		if [[ "$rel" == *..* ]] || [[ "$rel" == /* ]]; then
			log_error "audit: path must be relative with no .. (e.g. arch/misc.yaml)"
			return 1
		fi
		case "$rel" in
		*.yaml | *.yml) ;;
		*) rel="$rel.yaml" ;;
		esac
		local dir full
		dir="$DOTFILES_DIR/os/$(dirname "$rel")"
		full="$DOTFILES_DIR/os/$rel"
		mkdir -p "$dir"
		if [[ -e "$full" ]]; then
			log_warn "audit: file already exists — choose it from the list instead ($rel)"
			return 1
		fi
		printf '%s\n' 'modules:' >"$full"
		target_file="os/$rel"
	else
		target_file="$target_pick"
	fi

	local grouping
	grouping="$(gum choose \
		"One module for all selections" \
		"Separate module per package (name = package)")" || return 0

	if [[ "$grouping" == Separate* ]]; then
		local pkg ent
		for pkg in "${selected[@]}"; do
			ent="$(_audit_install_entry_for_pkg "$pkg")"
			_audit_append_module_block "$target_file" "$pkg" "$ent"
		done
		log_ok "audit: added ${#selected[@]} separate module(s) to $target_file"
		return 0
	fi

	local -a module_names=()
	while IFS= read -r name; do
		[[ -n "$name" ]] && module_names+=("$name")
	done < <(_audit_yaml_module_names_get "$DOTFILES_DIR/$target_file")
	module_names+=("[new module]")

	local target_module
	target_module=$(printf '%s\n' "${module_names[@]}" | gum filter --header "Select module")
	[[ -z "$target_module" ]] && return 0

	if [[ "$target_module" == "[new module]" ]]; then
		target_module=$(gum input --placeholder "module name")
		[[ -z "$target_module" ]] && return 0
		local -a entries=()
		for pkg in "${selected[@]}"; do
			entries+=("$(_audit_install_entry_for_pkg "$pkg")")
		done
		_audit_append_module_block "$target_file" "$target_module" "${entries[@]}"
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
