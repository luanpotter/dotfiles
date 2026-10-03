#!/usr/bin/env bash
# Build a clean Ubuntu image with the repo; Dockerfile runs a real ./update.sh (see test/Dockerfile).
# Repository root is always the parent of test/.
#
# Usage:
#   test/run.sh                 # docker build only
#   test/run.sh --assert        # CI: build + run idempotency & integration assertions
#   test/run.sh --shell         # interactive shell in the image
#   test/run.sh ./update.sh ... # docker run with command (e.g. ./update.sh --yes)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCKERFILE="$ROOT/test/Dockerfile"
IMAGE="${DOTFILES_DOCKER_TEST_IMAGE:-dotfiles-update-smoke}"

usage() {
	cat <<EOF
Usage: test/run.sh [--assert | --shell | COMMAND...]

  (no args)    Build $IMAGE; Dockerfile runs a real ./update.sh inside the image.
  --assert     CI mode: build image, then assert idempotency + integrations.
  --shell      Start an interactive shell in the image (docker run -it).
  COMMAND...   Run a command in a fresh container: test/run.sh ./update.sh --yes

  Override image name: DOTFILES_DOCKER_TEST_IMAGE=my-tag test/run.sh

EOF
}

if [[ "${1:-}" == -h || "${1:-}" == --help ]]; then
	usage
	exit 0
fi

docker build -t "$IMAGE" -f "$DOCKERFILE" "$ROOT"

if [[ "${1:-}" == --assert ]]; then
	# CI mode: image already ran ./update.sh during build; now assert idempotency + integrations
	docker run --rm "$IMAGE" bash -c '
		set -euo pipefail
		cd ~/dotfiles

		echo "==> Stage: dry-run (idempotency check)"
		# a second run right after the build must find nothing left to do
		dry_run_out=$(./update.sh --yes --dry-run --verbose 2>&1)
		printf "%s\n" "$dry_run_out"
		if grep -q "update needed" <<<"$dry_run_out"; then
			echo "FAIL: dry-run after a full update still has pending items"
			exit 1
		fi
		echo "PASS: second run is a no-op"

		echo "==> Stage: assertions"

		# 1. bootstrap tools must be available
		for tool in yq fzf; do
			command -v "$tool" >/dev/null || { echo "FAIL: $tool not found"; exit 1; }
		done
		echo "PASS: yq and fzf available"

		# 2. machine-local state lives outside the repo, written atomically
		env_file="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/env.yaml"
		[[ -f "$env_file" ]] || { echo "FAIL: $env_file not created"; exit 1; }
		[[ ! -e ~/dotfiles/env.yaml ]] || { echo "FAIL: env.yaml written inside the repo"; exit 1; }
		leftovers=("$env_file".*)
		[[ ! -e "${leftovers[0]}" ]] || { echo "FAIL: temp files left next to env.yaml: ${leftovers[*]}"; exit 1; }
		echo "PASS: env.yaml in ~/.config/dotfiles, no temp leftovers"

		# 3. Config symlink check (vim is in commons)
		if [[ -e ~/dotfiles/config/vim ]]; then
			[[ -L ~/.vimrc ]] || { echo "FAIL: ~/.vimrc not linked"; exit 1; }
			echo "PASS: vim config symlinked"
		fi

		# 4. Shell integration: up alias from functions.sh
		bash -ic "source ~/dotfiles/functions.sh && type up" >/dev/null || { echo "FAIL: up alias not defined"; exit 1; }
		echo "PASS: up alias defined"

		echo "==> All assertions passed!"
	'
elif [[ "${1:-}" == --shell ]]; then
	docker run --rm -it "$IMAGE" bash
elif [[ $# -gt 0 ]]; then
	docker run --rm "$IMAGE" "$@"
else
	printf 'Built image %q. Try: %q --assert  or  %q --shell  or  %q ./update.sh --yes\n' "$IMAGE" "$0" "$0" "$0"
fi
