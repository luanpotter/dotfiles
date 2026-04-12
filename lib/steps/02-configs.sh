#!/usr/bin/env bash

# step_configs iterates all modules with a config entry,
# symlinking config/<name> → target. Returns count of changes.
step_configs() {
	local manifest="$1"
	log_verbose_info "configs: checking symlinks"

	local -a names=()
	local -a targets=()
	while IFS=$'\t' read -r name target; do
		[[ -n "$name" ]] || continue
		names+=("$name")
		targets+=("$target")
	done < <(echo "$manifest" | yq -r '
		[.modules[] | select(.config) | [.name, .config]] | .[] | @tsv
	')

	local pending=0
	for i in "${!names[@]}"; do
		local name="${names[$i]}"
		local target="${targets[$i]}"

		# expand ~ to $HOME
		target="${target/#\~/$HOME}"

		local source="$DOTFILES_DIR/config/$name"

		if [[ ! -e "$source" ]]; then
			log_warn "configs: config/$name does not exist, skipping"
			continue
		fi

		# file-level config: if source is a dir and target basename exists inside,
		# symlink that specific file instead of the whole directory
		if [[ -d "$source" ]]; then
			local target_basename
			target_basename="$(basename "$target")"
			if [[ -e "$source/$target_basename" ]]; then
				source="$source/$target_basename"
			fi
		fi

		if [[ -L "$target" ]]; then
			local current
			current="$(readlink -f "$target")"
			if [[ "$current" == "$(readlink -f "$source")" ]]; then
				log_verbose "configs: $name already linked"
				continue
			fi
		fi

		pending=$((pending + 1))

		if [[ -e "$target" && ! -L "$target" ]]; then
			local backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d%H%M%S)"
			log_warn "configs: backing up $target → $backup_dir/"
			run_cmd mkdir -p "$backup_dir"
			run_cmd mv "$target" "$backup_dir/"
		fi

		log_info "configs: linking config/$name → $target"
		run_cmd mkdir -p "$(dirname "$target")"
		run_cmd ln -sfn "$source" "$target"
	done

	echo "$pending"
}
