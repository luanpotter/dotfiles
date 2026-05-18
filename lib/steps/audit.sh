#!/usr/bin/env bash

# -- per-manager: collect installed packages

_audit_collect_installed_pacman() {
	pacman -Qqe
}

_audit_collect_installed_apt() {
	apt-mark showmanual 2>/dev/null
}

_audit_collect_installed_brew() {
	brew list --formula 2>/dev/null
}

# -- per-manager: entry format for import

_audit_entry_format_pacman() {
	local pkg="$1"
	if pacman -Qm "$pkg" &>/dev/null; then
		printf 'aur:%s\n' "$pkg"
	else
		printf 'pacman:%s\n' "$pkg"
	fi
}

_audit_entry_format_apt() {
	printf 'apt:%s\n' "$1"
}

_audit_entry_format_brew() {
	printf 'brew:%s\n' "$1"
}

# -- per-manager: leaf filtering

_audit_leaf_filter_pacman() {
	local -a all=()
	while IFS= read -r pkg; do
		all+=("$pkg")
	done

	local -A set=()
	for pkg in "${all[@]}"; do
		set[$pkg]=1
	done

	local -A depended_on=()
	for pkg in "${all[@]}"; do
		local deps
		deps=$(pacman -Qi "$pkg" 2>/dev/null | sed -n 's/^Depends On *: *//p')
		[[ "$deps" == "None" ]] && continue
		for dep in $deps; do
			dep="${dep%%[><=]*}"
			[[ -n "${set[$dep]+x}" ]] && depended_on[$dep]=1
		done
	done

	for pkg in "${all[@]}"; do
		[[ -z "${depended_on[$pkg]+x}" ]] && printf '%s\n' "$pkg"
	done
}

_audit_leaf_filter_apt() {
	local -a all=()
	while IFS= read -r pkg; do
		all+=("$pkg")
	done

	local -A set=()
	for pkg in "${all[@]}"; do
		set[$pkg]=1
	done

	local -A depended_on=()
	for pkg in "${all[@]}"; do
		local dep
		while IFS= read -r dep; do
			[[ -n "$dep" ]] || continue
			[[ -n "${set[$dep]+x}" ]] && depended_on[$dep]=1
		done < <(apt-cache depends --installed "$pkg" 2>/dev/null | sed -n 's/^  Depends: //p')
	done

	for pkg in "${all[@]}"; do
		[[ -z "${depended_on[$pkg]+x}" ]] && printf '%s\n' "$pkg"
	done
}

# -- shared interactive flow

_audit_choose_action() {
	local header="$1"
	gum choose --header "$header" \
		"Import — add packages to a YAML module" \
		"Uninstall — remove packages from system" \
		"List — show all unmanaged packages" \
		"Done"
}

_audit_select_packages() {
	local header="$1"
	shift
	printf '%s\n' "$@" | gum filter --no-limit --header "$header"
}

_audit_yaml_target() {
	local -a yaml_choices=("[+] Create new YAML under os/")
	shopt -s nullglob globstar
	local f
	for f in "$DOTFILES_DIR/os"/**/*.yaml; do
		yaml_choices+=("${f#"$DOTFILES_DIR/"}")
	done
	shopt -u nullglob globstar
	printf '%s\n' "${yaml_choices[@]}" | gum filter --header "Select target YAML file"
}

_audit_create_yaml_file() {
	local placeholder="$1"
	local rel
	if ! rel=$(gum input --placeholder "$placeholder"); then
		return 0
	fi
	rel="${rel/#\//}"
	rel="${rel#"os/"}"
	[[ -z "$rel" ]] && return 0
	if [[ "$rel" == *..* ]] || [[ "$rel" == /* ]]; then
		log_error "audit: path must be relative with no .."
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
	printf '%s\n' "os/$rel"
}

_audit_import_to_yaml() {
	local target_file="$1" target_module="$2" entry_fmt_fn="$3"
	shift 3
	local file="$DOTFILES_DIR/$target_file"

	local name_line
	name_line=$(grep -n "name: $target_module" "$file" | head -1 | cut -d: -f1)
	if [[ -z "$name_line" ]]; then
		log_warn "audit: could not find module '$target_module' in $target_file"
		return 1
	fi

	for pkg in "$@"; do
		local entry
		entry=$("$entry_fmt_fn" "$pkg")
		local install_line
		install_line=$(tail -n +"$name_line" "$file" | grep -n 'install:' | head -1 | cut -d: -f1)
		if [[ -z "$install_line" ]]; then
			sed -i "${name_line}a\\    install:\\n      - $entry" "$file"
		else
			install_line=$((name_line + install_line - 1))
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
	log_ok "audit: added $# package(s) to module '$target_module' in $target_file"
}

_audit_run_import() {
	local mgr="$1" entry_fmt_fn="$2"
	shift 2
	local -a unmanaged=("$@")

	local -a selected=()
	while IFS= read -r pkg; do
		[[ -n "$pkg" ]] && selected+=("$pkg")
	done < <(_audit_select_packages "Select packages to import" "${unmanaged[@]}")

	if [[ ${#selected[@]} -eq 0 ]]; then
		log_info "audit: no packages selected"
		return 0
	fi

	local target_pick
	target_pick=$(_audit_yaml_target)
	[[ -z "$target_pick" ]] && return 0

	local target_file=""
	if [[ "$target_pick" == "[+] Create new YAML under os/" ]]; then
		target_file=$(_audit_create_yaml_file "relative path under os/, e.g. ${DOTFILES_PLATFORM}/misc.yaml")
		[[ -z "$target_file" ]] && return 0
	else
		target_file="$target_pick"
	fi

	local grouping
	grouping="$(gum choose \
		"One module for all selections" \
		"Separate module per package (name = package)")" || return 0

	if [[ "$grouping" == Separate* ]]; then
		local pkg
		for pkg in "${selected[@]}"; do
			local ent
			ent=$("$entry_fmt_fn" "$pkg")
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
			entries+=("$("$entry_fmt_fn" "$pkg")")
		done
		_audit_append_module_block "$target_file" "$target_module" "${entries[@]}"
		log_ok "audit: created module '$target_module' in $target_file with ${#selected[@]} package(s)"
	else
		_audit_import_to_yaml "$target_file" "$target_module" "$entry_fmt_fn" "${selected[@]}"
	fi
}

_audit_uninstall_pacman() {
	sudo pacman -Rns --noconfirm "$@"
}

_audit_uninstall_apt() {
	sudo apt-get remove --purge -y "$@"
}

_audit_uninstall_brew() {
	brew uninstall "$@"
}

_audit_run_uninstall() {
	local uninstall_fn="$1"
	shift
	local -a unmanaged=("$@")

	local -a selected=()
	while IFS= read -r pkg; do
		[[ -n "$pkg" ]] && selected+=("$pkg")
	done < <(_audit_select_packages "Select packages to uninstall" "${unmanaged[@]}")

	if [[ ${#selected[@]} -eq 0 ]]; then
		log_info "audit: no packages selected"
		return 0
	fi

	log_warn "audit: will uninstall ${selected[*]}"
	if gum confirm "Uninstall ${#selected[@]} package(s)?"; then
		"$uninstall_fn" "${selected[@]}"
		log_ok "audit: uninstalled ${#selected[@]} package(s)"
	else
		log_info "audit: cancelled"
	fi
}

# -- main audit flow

step_audit() {
	local manifest="$1"
	log_info "audit: checking for unmanaged packages"

	local mgr_list="${DOTFILES_MANAGERS_BY_PLATFORM[$DOTFILES_PLATFORM]:-}"
	if [[ -z "$mgr_list" ]]; then
		log_info "audit: no manager list for platform '$DOTFILES_PLATFORM'"
		return 0
	fi

	local -A declared=()
	_audit_collect_declared_all "$manifest" declared

	local total_installed=0 total_unmanaged=0
	local -a audit_managers=() audit_unmanaged=()

	for mgr in $mgr_list; do
		local -a installed=() leaves=() unmanaged=()
		local collect_fn="" leaf_fn="" fmt_fn="" uninstall_fn=""

		case "$mgr" in
		pacman|aur)
			collect_fn="_audit_collect_installed_pacman"
			leaf_fn="_audit_leaf_filter_pacman"
			fmt_fn="_audit_entry_format_pacman"
			uninstall_fn="_audit_uninstall_pacman"
			;;
		apt)
			collect_fn="_audit_collect_installed_apt"
			leaf_fn="_audit_leaf_filter_apt"
			fmt_fn="_audit_entry_format_apt"
			uninstall_fn="_audit_uninstall_apt"
			;;
		brew)
			collect_fn="_audit_collect_installed_brew"
			fmt_fn="_audit_entry_format_brew"
			uninstall_fn="_audit_uninstall_brew"
			;;
		*)
			log_verbose "audit: skipping manager '$mgr' (no audit support)"
			continue
			;;
		esac

		# collect installed
		if ! check_cmd "$mgr" && [[ "$mgr" != pacman && "$mgr" != aur ]]; then
			log_verbose "audit: $mgr not installed, skipping"
			continue
		fi
		# pacman is special: aur lines are tracked in pacman -Qqe, but the
		# aur binary itself may not exist.  We still audit pacman/aur if
		# pacman is present.
		if [[ "$mgr" == pacman || "$mgr" == aur ]]; then
			if ! check_cmd pacman; then
				log_verbose "audit: pacman not installed, skipping"
				continue
			fi
		fi

		mapfile -t installed < <("$collect_fn")
		if [[ ${#installed[@]} -eq 0 ]]; then
			log_verbose "audit: no installed packages for $mgr"
			continue
		fi

		# find unmanaged
		for pkg in "${installed[@]}"; do
			if [[ -z "${declared[$pkg]+x}" ]]; then
				unmanaged+=("$pkg")
			fi
		done
		if [[ ${#unmanaged[@]} -eq 0 ]]; then
			log_ok "audit: all ${#installed[@]} $mgr packages are tracked"
			continue
		fi

		# leaf filtering (if available)
		if [[ -n "$leaf_fn" ]]; then
			mapfile -t leaves < <(printf '%s\n' "${unmanaged[@]}" | "$leaf_fn")
			log_warn "audit: ${#leaves[@]} unmanaged leaf $mgr package(s) out of ${#installed[@]} installed (${#unmanaged[@]} total unmanaged)"
		else
			leaves=("${unmanaged[@]}")
			log_warn "audit: ${#leaves[@]} unmanaged $mgr package(s) out of ${#installed[@]} installed"
		fi

		audit_managers+=("$mgr")
		audit_unmanaged+=("$mgr" "${leaves[@]}")
		total_installed=$((total_installed + ${#installed[@]}))
		total_unmanaged=$((total_unmanaged + ${#leaves[@]}))
	done

	if [[ ${#audit_managers[@]} -eq 0 ]]; then
		log_info "audit: no supported managers with installed packages"
		return 0
	fi

	if [[ $total_unmanaged -eq 0 ]]; then
		log_ok "audit: all packages tracked across ${#audit_managers[@]} manager(s)"
		return 0
	fi

	if ! check_cmd gum; then
		local i=0
		while [[ $i -lt ${#audit_unmanaged[@]} ]]; do
			local mgr="${audit_unmanaged[i]}"
			((i++))
			local -a pkgs=()
			while [[ $i -lt ${#audit_unmanaged[@]} && "${audit_unmanaged[i]}" != @(pacman|aur|apt|brew|snap) ]]; do
				pkgs+=("${audit_unmanaged[i]}")
				((i++))
			done
			printf '%s\n' "${pkgs[@]}"
		done
		return 0
	fi

	# interactive: choose manager, then action
	local chosen_mgr
	if [[ ${#audit_managers[@]} -eq 1 ]]; then
		chosen_mgr="${audit_managers[0]}"
	else
		chosen_mgr=$(printf '%s\n' "${audit_managers[@]}" | gum filter --header "Select manager to audit")
		[[ -z "$chosen_mgr" ]] && return 0
	fi

	local -a chosen_pkgs=()
	local i=0
	while [[ $i -lt ${#audit_unmanaged[@]} ]]; do
		local mgr="${audit_unmanaged[i]}"
		((i++))
		local -a pkgs=()
		while [[ $i -lt ${#audit_unmanaged[@]} && "${audit_unmanaged[i]}" != @(pacman|aur|apt|brew|snap) ]]; do
			pkgs+=("${audit_unmanaged[i]}")
			((i++))
		done
		if [[ "$mgr" == "$chosen_mgr" ]]; then
			chosen_pkgs=("${pkgs[@]}")
			break
		fi
	done

	local action
	action=$(_audit_choose_action "Unmanaged $chosen_mgr packages — what would you like to do?") || return 0

	local fmt_fn="" uninstall_fn=""
	case "$chosen_mgr" in
	pacman|aur)
		fmt_fn="_audit_entry_format_pacman"
		uninstall_fn="_audit_uninstall_pacman"
		;;
	apt)
		fmt_fn="_audit_entry_format_apt"
		uninstall_fn="_audit_uninstall_apt"
		;;
	brew)
		fmt_fn="_audit_entry_format_brew"
		uninstall_fn="_audit_uninstall_brew"
		;;
	esac

	case "$action" in
	Import*)
		_audit_run_import "$chosen_mgr" "$fmt_fn" "${chosen_pkgs[@]}"
		;;
	Uninstall*)
		_audit_run_uninstall "$uninstall_fn" "${chosen_pkgs[@]}"
		;;
	List*)
		printf '%s\n' "${chosen_pkgs[@]}" | gum pager
		;;
	Done) ;;
	esac
}
