#!/usr/bin/env bash
# Run shellcheck on every bash script in the repository.
# Can be run locally.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$ROOT"

# Find all files with a bash shebang, excluding .git/ and vendored completions
mapfile -t scripts < <(find . -type f -not -path './.git/*' -not -path './scripts/.git-completion.bash' -exec grep -l '^#!.*bash' {} \; 2>/dev/null | sort)

if [[ ${#scripts[@]} -eq 0 ]]; then
	echo "No shell scripts found."
	exit 0
fi

# SC1090/SC1091: ShellCheck can't follow dynamic/non-constant `source` paths.
# We source files by glob ("$LIB/steps/*.sh") and via runtime-resolved paths
# (e.g. "$DOTFILES_DIR/lib/detect.sh"). These are by design; disabling the
# rule globally avoids boilerplate per-source comments without weakening any
# other checks (quoting, unused vars, etc.).
echo "==> Running shellcheck on ${#scripts[@]} file(s)"
shellcheck -x --exclude=SC1090,SC1091 "${scripts[@]}"
echo "==> All shell scripts passed shellcheck"
