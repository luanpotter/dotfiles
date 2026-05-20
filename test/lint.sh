#!/usr/bin/env bash
# Formats and lints every bash script in the repository.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# shellcheck source=lib/utils.sh
source "$ROOT/lib/utils.sh"

FIX=false
case "${1:-}" in
"") ;;
--fix) FIX=true ;;
-h | --help)
	echo "Usage: $0 [--fix]"
	echo "  --fix   Auto-fix formatting (shfmt -w) instead of diff-only check"
	exit 0
	;;
*)
	echo "Unknown arg: $1 (try --help)" >&2
	exit 2
	;;
esac

mapfile -t scripts < <(find . -type f -not -path './.git/*' -not -path './scripts/.git-completion.bash' -exec grep -l '^#!.*bash' {} \; 2>/dev/null | sort)

if [[ ${#scripts[@]} -eq 0 ]]; then
	echo "No shell scripts found."
	exit 0
fi

run_tool() {
	local name="$1"
	shift
	if ! check_cmd "$name"; then
		echo "$name not found. Install: brew install $name  /  apt install $name" >&2
		return 1
	fi
	echo "==> Running $name on ${#scripts[@]} file(s)"
	"$name" "$@" "${scripts[@]}"
	echo "==> $name passed"
}

# SC1090/SC1091: ShellCheck can't follow dynamic/non-constant `source` paths.
run_tool shellcheck -x --exclude=SC1090,SC1091

if [[ "$FIX" == true ]]; then
	run_tool shfmt -w
else
	run_tool shfmt -d
fi

echo "==> All shell scripts passed lint"
