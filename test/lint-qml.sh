#!/usr/bin/env bash
# Lints the quickshell QML config with qmllint; any warning fails.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# on Arch, /usr/bin/qmllint is Qt 5's; Qt 6's lives in Qt's bin dir
qmllint=""
if [[ -x /usr/lib/qt6/bin/qmllint ]]; then
	qmllint=/usr/lib/qt6/bin/qmllint
else
	qmllint="$(command -v qmllint6 || command -v qmllint || true)"
fi
# Qt 5's reports "qmllint 1.0", Qt 6's its Qt version
if [[ -z "$qmllint" ]] || ! "$qmllint" --version | grep -q 'qmllint 6\.'; then
	echo "==> Qt 6 qmllint not found, skipping QML lint (Arch: qt6-declarative)"
	exit 0
fi

# lint a copy with a generated qmldir, so qmllint knows the singletons
# (quickshell registers them itself at runtime)
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
# .js too: QML imports those by relative path
find "$ROOT/config/quickshell" -maxdepth 1 \( -name '*.qml' -o -name '*.js' \) -exec cp {} "$tmp/" \;
{
	echo "module shell"
	for f in "$tmp"/*.qml; do
		name="$(basename "$f" .qml)"
		if grep -q '^pragma Singleton' "$f"; then
			echo "singleton $name 1.0 $name.qml"
		else
			echo "$name 1.0 $name.qml"
		fi
	done
} >"$tmp/qmldir"

# patched copy of quickshell's type info, for three upstream gaps (each patch
# skips itself once fixed):
# - Edges::Flags is never registered (missing Q_FLAG_NS)
# - submodule qmldirs don't declare `depends Quickshell`
# - since 0.3.2, module qmltypes stub other modules' types (PopupAnchor,
#   UntypedObjectModel) as opaque, memberless components that shadow the real
#   ones; only stubs with a real definition elsewhere are dropped
# upstream fix for the missing type info, open as of 2026-10:
# https://github.com/quickshell-mirror/quickshell/pull/1220
qt_qml="$(cd "$(dirname "$qmllint")/../qml" 2>/dev/null && pwd || echo /usr/lib/qt6/qml)"
qs_types="$qt_qml/Quickshell"
if [[ -d "$qs_types" ]]; then
	mkdir -p "$tmp/imports"
	cp -r "$qs_types" "$tmp/imports/Quickshell"
	core="$tmp/imports/Quickshell/quickshell-core.qmltypes"
	if ! grep -A12 'name: "Edges"$' "$core" | grep -q 'isFlag: true'; then
		sed "/name: \"Edges\"\$/r $ROOT/test/qml-shims/edges-flags.qmltypes" "$core" >"$core.tmp"
		mv "$core.tmp" "$core"
	fi
	while IFS= read -r qmldir; do
		grep -q '^depends Quickshell$' "$qmldir" || echo "depends Quickshell" >>"$qmldir"
	done < <(find "$tmp/imports/Quickshell" -mindepth 2 -name qmldir)
	# real definitions are multi-line, so their name sits on its own line
	while IFS= read -r name; do
		echo "/^ *Component { isTypeOpaque: true; name: \"$name\";/d"
	done < <(grep -rh '^        name: "' "$tmp/imports/Quickshell" --include='*.qmltypes' |
		sed 's/^ *name: "\(.*\)"$/\1/' | sort -u) >"$tmp/drop-stubs.sed"
	while IFS= read -r types; do
		sed -f "$tmp/drop-stubs.sed" "$types" >"$types.tmp"
		mv "$types.tmp" "$types"
	done < <(find "$tmp/imports/Quickshell" -name '*.qmltypes')
fi

files=("$tmp"/*.qml)
echo "==> Running qmllint on ${#files[@]} file(s)"
# --bare: otherwise Qt's import dir wins over -I and bypasses the patch.
# Disabled, false positives only:
# - uncreatable-type: quickshell's windows are marked uncreatable
# - signal-handler-parameters: Qt enums missing from the type files
(cd "$tmp" && "$qmllint" --max-warnings 0 \
	--bare -I "$tmp/imports" -I "$qt_qml" \
	--uncreatable-type disable \
	--signal-handler-parameters disable \
	"${files[@]}")
echo "==> qmllint passed"
