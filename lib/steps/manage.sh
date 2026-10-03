#!/usr/bin/env bash

# step_manage allows viewing and editing module statuses.
step_manage() {
	# manifest is intentionally ignored; this step reads raw os/ YAMLs directly.
	if ! check_cmd fzf; then
		log_error "manage: fzf is required for the TUI"
		return 1
	fi

	# read all modules (including filtered-out ones) from raw YAML files
	local commons_dir="$DOTFILES_DIR/os/commons"
	local platform_dir="$DOTFILES_DIR/os/$DOTFILES_PLATFORM"
	local -a files=()
	shopt -s nullglob globstar
	for dir in "$commons_dir" "$platform_dir"; do
		[[ -d "$dir" ]] || continue
		for f in "$dir"/**/*.yaml; do
			files+=("$f")
		done
	done
	shopt -u nullglob globstar

	# get all module names with their default field
	local -a names=()
	local -A defaults=()
	while IFS=$'\t' read -r name default; do
		[[ -n "$name" ]] || continue
		names+=("$name")
		defaults[$name]="$default"
	done < <(yq -r -s '[.[] | (.modules // [])[] | [.name, (if .default == false then "false" else "true" end)]] | .[] | @tsv' "${files[@]}")

	_ensure_env
	local header="Tab: mark · Enter: toggle marked (or current) · Esc: done"

	while true; do
		# re-read env.yaml overrides each round, so the list reflects the last save
		local -A overrides=()
		while IFS=$'\t' read -r name val; do
			[[ -n "$name" ]] || continue
			overrides[$name]="$val"
		done < <(yq -r '.modules // {} | to_entries[] | [.key, (.value | tostring)] | @tsv' "$ENV_FILE")

		# one line per module: "[x] name  (default|override)"
		local -A enabled=()
		local -a lines=()
		for name in "${names[@]}"; do
			local state="${defaults[$name]}" origin="default"
			if [[ -n "${overrides[$name]+x}" ]]; then
				state="${overrides[$name]}"
				origin="override"
			fi
			enabled[$name]="$state"
			local box="[ ]"
			if [[ "$state" == true ]]; then
				box="[x]"
			fi
			lines+=("$(printf '%s %-20s (%s)' "$box" "$name" "$origin")")
		done

		# Esc / Ctrl+C just leave: every toggle is already saved
		local picked rc=0
		picked=$(printf '%s\n' "${lines[@]}" | _ui_fzf --multi --header "$header") || rc=$?
		if [[ $rc -eq $UI_BACK || $rc -eq 130 ]]; then
			break
		elif [[ $rc -ne 0 ]]; then
			continue
		fi

		# flip each picked module; drop the override when it lands on the default
		local tmp
		tmp=$(yq -y '.' "$ENV_FILE")
		local line
		while IFS= read -r line; do
			[[ -n "$line" ]] || continue
			# lines are "[x] name ..." / "[ ] name ...": skip the 4-char box
			local name="${line:4}"
			name="${name%% *}"
			local new=true label=enabled
			if [[ "${enabled[$name]}" == true ]]; then
				new=false
				label=disabled
			fi
			if [[ "$new" == "${defaults[$name]}" ]]; then
				tmp=$(printf '%s\n' "$tmp" | yq -y "del(.modules.\"$name\")")
			else
				tmp=$(printf '%s\n' "$tmp" | yq -y ".modules.\"$name\" = $new")
			fi
			log_ok "manage: $name → $label"
		done <<<"$picked"
		env_write "$tmp"
	done

	log_ok "manage: done"
}
