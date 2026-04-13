#!/usr/bin/env bash

step_pull() {
	local branch
	branch="$(git -C "$DOTFILES_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
	if [[ "$branch" == "master" ]] && git -C "$DOTFILES_DIR" diff --quiet 2>/dev/null &&
		git -C "$DOTFILES_DIR" diff --cached --quiet 2>/dev/null; then
		log_info "pulling latest from master"
		run_cmd git -C "$DOTFILES_DIR" pull --ff-only
	else
		log_warn "running with local changes (branch=$branch)"
	fi
}
