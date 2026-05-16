#!/usr/bin/env bash

step_upgrade() {
	log_info "upgrading system packages"
	case "$DOTFILES_PLATFORM" in
	arch)
		run_cmd sudo pacman -Syu --noconfirm
		;;
	debian)
		run_cmd sudo apt-get update
		run_cmd sudo apt-get upgrade -y
		;;
	*)
		log_verbose "upgrade: no recipe for platform '$DOTFILES_PLATFORM'"
		;;
	esac
}
