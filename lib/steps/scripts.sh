#!/usr/bin/env bash

# step_scripts symlinks the scripts/ directory into ~/bin/scripts
step_scripts() {
	log_verbose_info "scripts: checking symlink into ~/bin"

	local src="$DOTFILES_DIR/scripts"
	local target="$HOME/bin/scripts"

	if [[ ! -d "$src" ]]; then
		log_warn "scripts: $src does not exist, skipping"
		echo "0"
		return 0
	fi

	run_cmd mkdir -p "$(dirname "$target")"

	if [[ -L "$target" ]]; then
		local current
		current="$(readlink -f "$target")"
		if [[ "$current" == "$(readlink -f "$src")" ]]; then
			log_verbose "scripts: already linked"
		else
			log_warn "scripts: incorrectly linked"
		fi
		echo "0"
		return 0
	fi

	log_info "scripts: linking $src → $target"
	run_cmd ln -sfn "$src" "$target"
	echo "1"
}
