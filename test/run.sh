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
	# CI mode: image already ran ./update.sh during build; now assert the result
	docker run --rm "$IMAGE" ./test/assert.sh
elif [[ "${1:-}" == --shell ]]; then
	docker run --rm -it "$IMAGE" bash
elif [[ $# -gt 0 ]]; then
	docker run --rm "$IMAGE" "$@"
else
	printf 'Built image %q. Try: %q --assert  or  %q --shell  or  %q ./update.sh --yes\n' "$IMAGE" "$0" "$0" "$0"
fi
