#!/usr/bin/env bash

step_upgrade() {
	log_info "upgrading system packages"

	local mgr_list="${DOTFILES_MANAGERS_BY_PLATFORM[$DOTFILES_PLATFORM]:-}"
	for mgr in $mgr_list; do
		case "$mgr" in
		pacman) _upgrade_pacman ;;
		aur)    _upgrade_aur ;;
		apt)    _upgrade_apt ;;
		brew)   _upgrade_brew ;;
		snap)   _upgrade_snap ;;
		*)      log_warn "upgrade: no update recipe for manager '$mgr'" ;;
		esac
	done
}

_upgrade_pacman() {
	if check_cmd pacman; then
		run_cmd sudo pacman -Syu --noconfirm
	else
		log_warn "upgrade: pacman not found, skipping"
	fi
}

_upgrade_aur() {
	if check_cmd yay; then
		run_cmd yay -Sua --noconfirm
	else
		log_warn "upgrade: yay not found, skipping AUR updates"
	fi
}

_upgrade_apt() {
	if check_cmd apt-get; then
		run_cmd sudo apt-get update
		run_cmd sudo apt-get upgrade -y
	else
		log_warn "upgrade: apt-get not found, skipping"
	fi
}

_upgrade_brew() {
	if check_cmd brew; then
		run_cmd brew update
		run_cmd brew upgrade
	else
		log_warn "upgrade: Homebrew not found"
	fi
}

_upgrade_snap() {
	if ! check_cmd snap; then
		log_verbose "upgrade: snap not found, skipping"
		return 0
	fi
	local snapd_running=false
	if check_cmd systemctl && systemctl is-active --quiet snapd 2>/dev/null; then
		snapd_running=true
	elif check_cmd pgrep && pgrep -x snapd &>/dev/null; then
		snapd_running=true
	fi
	if $snapd_running; then
		log_info "upgrade: refreshing snap packages"
		run_cmd sudo snap refresh
	else
		log_verbose "upgrade: snapd not running, skipping snap refresh"
	fi
}
