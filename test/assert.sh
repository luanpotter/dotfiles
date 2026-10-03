#!/usr/bin/env bash
# Assertions run inside the test image, after the build's ./update.sh --yes.
# Checks every claim the engine makes against the merged manifest, collects
# all failures, and exits non-zero if any. Usage: test/run.sh --assert
set -euo pipefail

# shellcheck source=lib/utils.sh
source "$(cd "$(dirname "$0")/.." && pwd)/lib/utils.sh"
cd "$DOTFILES_DIR"

failures=0
pass() { printf 'PASS: %s\n' "$*"; }
fail() {
	printf 'FAIL: %s\n' "$*"
	failures=$((failures + 1))
}
stage() { printf '\n==> %s\n' "$*"; }

manifest="$(merge_manifests)"

stage "platform"
expected_platform="${EXPECTED_PLATFORM:-debian}"
if [[ "$DOTFILES_PLATFORM" == "$expected_platform" ]]; then
	pass "detected platform '$DOTFILES_PLATFORM'"
else
	fail "detected platform '$DOTFILES_PLATFORM', expected '$expected_platform'"
fi

stage "idempotency: a second run must be a no-op"
dry_run_rc=0
dry_run_out=$(./update.sh --yes --dry-run --verbose 2>&1) || dry_run_rc=$?
printf '%s\n' "$dry_run_out"
if [[ $dry_run_rc -ne 0 ]]; then
	fail "dry-run exited $dry_run_rc"
elif grep -q "update needed" <<<"$dry_run_out"; then
	fail "dry-run after a full update still has pending items"
else
	pass "second run is a no-op"
fi

stage "bootstrap tools"
for tool in yq fzf; do
	if check_cmd "$tool"; then
		pass "$tool available"
	else
		fail "$tool not found"
	fi
done

stage "packages: every apt entry is actually installed"
# install failures inside steps don't stop update.sh, so verify the result
while IFS= read -r entry; do
	[[ "$entry" == apt:* ]] || continue
	pkg="${entry#apt:}"
	if dpkg -s "$pkg" &>/dev/null; then
		pass "apt: $pkg installed"
	else
		fail "apt: $pkg not installed"
	fi
done < <(printf '%s\n' "$manifest" | yq -r '[.modules[].install // [] | .[]] | unique | .[]')

stage "configs: every config target links into the repo"
while IFS=$'\t' read -r name target; do
	[[ -n "$name" ]] || continue
	target="${target/#\~/$HOME}"
	source_path="$DOTFILES_DIR/config/$name"
	# the engine skips modules with no config/<name>; nothing to check
	[[ -e "$source_path" ]] || continue
	# same file-level rule as step_configs
	if [[ -d "$source_path" && -e "$source_path/$(basename "$target")" ]]; then
		source_path="$source_path/$(basename "$target")"
	fi
	if [[ ! -L "$target" ]]; then
		fail "config $name: $target is not a symlink"
	elif [[ "$(readlink -f "$target")" != "$(readlink -f "$source_path")" ]]; then
		fail "config $name: $target -> $(readlink -f "$target"), expected $source_path"
	else
		pass "config $name linked"
	fi
done < <(printf '%s\n' "$manifest" | yq -r '[.modules[] | select(.config) | [.name, .config]] | .[] | @tsv')

stage "scripts"
if [[ -L ~/bin/scripts && "$(readlink -f ~/bin/scripts)" == "$(readlink -f "$DOTFILES_DIR/scripts")" ]]; then
	pass "scripts linked at $HOME/bin/scripts"
else
	fail "$HOME/bin/scripts not linked to $DOTFILES_DIR/scripts"
fi

stage "env.yaml: outside the repo, written atomically"
if [[ -f "$ENV_FILE" ]]; then
	pass "env.yaml at $ENV_FILE"
else
	fail "$ENV_FILE not created"
fi
if [[ -e "$DOTFILES_DIR/env.yaml" ]]; then
	fail "env.yaml written inside the repo"
else
	pass "no env.yaml inside the repo"
fi
leftovers=("$ENV_FILE".*)
if [[ -e "${leftovers[0]}" ]]; then
	fail "temp files left next to env.yaml: ${leftovers[*]}"
else
	pass "no temp files next to env.yaml"
fi

stage "exec: every exec block ran and recorded its current hash"
while IFS= read -r name; do
	[[ -n "$name" ]] || continue
	# hash exactly as step_exec does
	exec_block=$(printf '%s\n' "$manifest" | yq -r ".modules[] | select(.name == \"$name\") | .exec")
	want=$(printf '%s' "$exec_block" | sha256sum | cut -d' ' -f1)
	got=$(env_get_hash "$name")
	if [[ "$got" == "$want" ]]; then
		pass "exec $name recorded"
	elif [[ -z "$got" ]]; then
		fail "exec $name has no recorded hash"
	else
		fail "exec $name recorded a stale hash"
	fi
done < <(printf '%s\n' "$manifest" | yq -r '.modules[] | select(.exec) | .name')

stage "shell integration: functions.sh loads cleanly"
# functions.sh is for interactive shells and uses its own aliases (src), so
# expand aliases like an interactive shell would (bash -i adds tty noise)
# shellcheck disable=SC2016 # expanded by the inner bash
shell_err=$(bash -c 'shopt -s expand_aliases; source "$1" && alias up' _ "$DOTFILES_DIR/functions.sh" 2>&1 >/dev/null) || fail "sourcing functions.sh failed"
if [[ -n "$shell_err" ]]; then
	fail "functions.sh printed errors:"
	printf '%s\n' "$shell_err"
else
	pass "functions.sh sourced with no errors"
fi
# shellcheck disable=SC2016 # expanded by the inner bash
up_alias=$(bash -c 'shopt -s expand_aliases; source "$1" 2>/dev/null; alias up' _ "$DOTFILES_DIR/functions.sh" || true)
up_path="${up_alias#*=\'}"
up_path="${up_path%\'}"
up_path="${up_path/#\~/$HOME}"
if [[ -x "$up_path" ]]; then
	pass "up alias -> $up_path"
else
	fail "up alias missing or not executable: '${up_alias:-<none>}'"
fi

printf '\n'
if [[ $failures -gt 0 ]]; then
	printf '==> %d assertion(s) failed\n' "$failures"
	exit 1
fi
printf '==> All assertions passed!\n'
