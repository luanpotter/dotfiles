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
		./update.sh --yes --dry-run --verbose

		echo "==> Stage: assertions"

		# 1. yq must be available
		command -v yq >/dev/null || { echo "FAIL: yq not found"; exit 1; }
		echo "PASS: yq available"

		# 2. Config symlink check (vim is in commons)
		if [[ -e ~/dotfiles/config/vim ]]; then
			[[ -L ~/.vimrc ]] || { echo "FAIL: ~/.vimrc not linked"; exit 1; }
			echo "PASS: vim config symlinked"
		fi

		# 3. Shell integration: up alias from functions.sh
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
