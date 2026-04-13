#!/usr/bin/env bash

# step_manage shows all modules with their enabled/disabled status
# and lets the user toggle them via gum. Writes overrides to env.yaml.
step_manage() {
	local manifest="$1"
	log_info "manage: listing all modules"

	if ! command -v gum &>/dev/null; then
		log_error "manage: gum is required for the TUI"
		return 1
	fi

	# read all modules (including filtered-out ones) from raw YAML files
	local commons_dir="$DOTFILES_DIR/os/commons"
	local platform_dir="$DOTFILES_DIR/os/$PLATFORM"
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
	done < <(yq -s '[.[] | (.modules // [])[] | [.name, (.default // "null" | tostring)]] | .[] | @tsv' "${files[@]}")

	# read current env.yaml overrides
	local -A overrides=()
	while IFS=$'\t' read -r name val; do
		[[ -n "$name" ]] || continue
		overrides[$name]="$val"
	done < <(yq -r '.modules // {} | to_entries[] | [.key, (.value | tostring)] | @tsv' "$ENV_FILE")

	# resolve effective status for each module
	local -a enabled_names=()
	local -a display_lines=()
	for name in "${names[@]}"; do
		local status
		if [[ -n "${overrides[$name]+x}" ]]; then
			if [[ "${overrides[$name]}" == "true" ]]; then
				status="enabled (override)"
			else
				status="disabled (override)"
			fi
		elif [[ "${defaults[$name]}" == "false" ]]; then
			status="disabled (default)"
		else
			status="enabled"
		fi

		display_lines+=("$name [$status]")
		# track currently enabled for preselection
		if [[ "$status" == enabled* ]]; then
			enabled_names+=("$name")
		fi
	done

	# show current status
	log_info "manage: ${#names[@]} module(s) found"
	printf '%s\n' "${display_lines[@]}" >&2

	echo >&2
	if ! gum confirm "Edit module selection?"; then
		return 0
	fi

	# build gum choose args with preselected items
	local -a gum_args=(--no-limit --header "Toggle modules (space to select/deselect)")
	for name in "${enabled_names[@]}"; do
		gum_args+=(--selected "$name")
	done

	local -a selected=()
	while IFS= read -r name; do
		[[ -n "$name" ]] && selected+=("$name")
	done < <(printf '%s\n' "${names[@]}" | gum choose "${gum_args[@]}")

	# build new overrides: compare selection against defaults
	local -A new_overrides=()
	for name in "${names[@]}"; do
		local is_selected=false
		for s in "${selected[@]}"; do
			if [[ "$s" == "$name" ]]; then
				is_selected=true
				break
			fi
		done

		local default_enabled=true
		[[ "${defaults[$name]}" == "false" ]] && default_enabled=false

		# only write override if it differs from the default
		if [[ "$is_selected" == true && "$default_enabled" == false ]]; then
			new_overrides[$name]=true
		elif [[ "$is_selected" == false && "$default_enabled" == true ]]; then
			new_overrides[$name]=false
		fi
		# if selection matches default, no override needed
	done

	# write overrides to env.yaml
	_ensure_env
	local tmp
	tmp=$(yq -y '.modules = {}' "$ENV_FILE")
	printf '%s\n' "$tmp" >"$ENV_FILE"

	for name in "${!new_overrides[@]}"; do
		tmp=$(yq -y ".modules.\"$name\" = ${new_overrides[$name]}" "$ENV_FILE")
		printf '%s\n' "$tmp" >"$ENV_FILE"
	done

	local override_count=${#new_overrides[@]}
	if [[ $override_count -eq 0 ]]; then
		log_ok "manage: all modules at default, no overrides needed"
	else
		log_ok "manage: wrote $override_count override(s) to env.yaml"
	fi
}
