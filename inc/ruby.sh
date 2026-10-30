#!/usr/bin/env bash
# needs add_path_if_exists and $platform from functions.sh

# linux: system ruby, gems installed per user
# shellcheck disable=SC2154 # platform is set by functions.sh
if [[ "$platform" == "linux" ]]; then
	if command -v gem &>/dev/null; then
		GEM_HOME="$(gem env user_gemhome)"
		export GEM_HOME
		add_path_if_exists "$GEM_HOME/bin"
	fi
fi

# rvm's ready-made commands for the default ruby; loading rvm itself is slow.
# to switch rubies in a shell, run: source ~/.rvm/scripts/rvm
add_path_if_exists "$HOME/.rvm/bin"
add_path_if_exists "$HOME/.rvm/wrappers/default"
