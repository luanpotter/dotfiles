#!/usr/bin/env bash
# needs add_path_if_exists and remove_from_path from functions.sh

# linux: system nvm, already fast
if [[ -f /usr/share/nvm/init-nvm.sh ]]; then
	source /usr/share/nvm/init-nvm.sh
	return
fi

[[ -s "$XDG_CONFIG_HOME/nvm/nvm.sh" ]] || return

# macos: plain nvm.sh costs ~1.5s, nearly all in its startup `nvm use`.
# skip it and put the default version on PATH from a cache instead
export NVM_DIR="$XDG_CONFIG_HOME/nvm"
source "$NVM_DIR/nvm.sh" --no-use

# rebuild the cache; run after changing the default alias
nvm_default_refresh() {
	local bin
	bin=$(dirname "$(nvm which default)") || return 1
	printf '%s\n' "$bin" >"$NVM_DIR/.default-bin"
	remove_from_path "$bin"
	add_path_if_exists "$bin"
}

if [[ -s "$NVM_DIR/.default-bin" ]] && [[ -d "$(<"$NVM_DIR/.default-bin")" ]]; then
	add_path_if_exists "$(<"$NVM_DIR/.default-bin")"
else
	nvm_default_refresh
fi
