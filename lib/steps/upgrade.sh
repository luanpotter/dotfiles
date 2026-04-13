#!/usr/bin/env bash

step_upgrade() {
	log_info "upgrading system packages"
	run_cmd sudo pacman -Syu --noconfirm
}
