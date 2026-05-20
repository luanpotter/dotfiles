#!/usr/bin/env bash
# lib/detect.sh — sets DOTFILES_PLATFORM for the dotfiles engine.
# Requires: DOTFILES_DIR (repo root) set by lib/utils.sh before sourcing.
#
# Global:
#   DOTFILES_PLATFORM — Slug for os/<slug>/ manifests and YAML env: filters.
#     Values: arch, debian, macos, truenas, unknown.

_dotfiles_os_release_field() {
	local file="$1" key="$2"
	local line
	line="$(grep -E "^${key}=" "$file" 2>/dev/null | head -1)" || true
	[[ -z "$line" ]] && return 0
	line="${line#*=}"
	line="${line#\"}"
	line="${line%\"}"
	line="${line#\'}"
	line="${line%\'}"
	line="${line,,}"
	printf '%s' "$line"
}

dotfiles_detect_os() {
	if [[ "$OSTYPE" == darwin* ]]; then
		DOTFILES_PLATFORM=macos
		return 0
	fi

	local release=/etc/os-release
	if [[ ! -r "$release" ]]; then
		DOTFILES_PLATFORM=unknown
		return 0
	fi

	local id variant id_like
	id="$(_dotfiles_os_release_field "$release" ID)"
	variant="$(_dotfiles_os_release_field "$release" VARIANT_ID)"
	id_like="$(_dotfiles_os_release_field "$release" ID_LIKE)"

	DOTFILES_PLATFORM="$id"
	if [[ -n "$variant" && -d "$DOTFILES_DIR/os/$variant" ]]; then
		DOTFILES_PLATFORM="$variant"
	fi

	case "$DOTFILES_PLATFORM" in
	debian | ubuntu)
		DOTFILES_PLATFORM=debian
		;;
	esac
	if [[ "$DOTFILES_PLATFORM" != debian && "$DOTFILES_PLATFORM" == "$id" ]]; then
		if [[ -n "$id_like" ]] && [[ "${id_like}" == *debian* || "${id_like}" == *ubuntu* ]]; then
			DOTFILES_PLATFORM=debian
		fi
	fi
}

# Prints DOTFILES_PLATFORM plus useful /etc/os-release lines (no extra globals).
dotfiles_print_platform() {
	printf 'DOTFILES_PLATFORM=%q\n' "${DOTFILES_PLATFORM}"
	printf '# context:\n'
	if [[ "$OSTYPE" == darwin* ]]; then
		printf 'OSTYPE=%q\n' "${OSTYPE}"
	elif [[ -r /etc/os-release ]]; then
		grep -E '^(ID|ID_LIKE|VARIANT_ID|NAME)=' /etc/os-release || true
	else
		printf '(no /etc/os-release)\n'
	fi
}

dotfiles_detect_os
