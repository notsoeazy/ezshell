#!/usr/bin/env bash
# Lints and format-checks our QML. Run the shell once first (`qs -p .`), since
# Quickshell generates the module tree the linter resolves `qs.*` imports from.
set -euo pipefail

# /usr/bin/qmllint may be the Qt 5 build, which rejects Qt 6 syntax silently.
qt_bin="${QT6_BIN:-/usr/lib/qt6/bin}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

build_dir=""
# .qmlls.ini is a link Quickshell points at its tooling directory; it dangles
# once that instance has gone.
if [[ -r .qmlls.ini ]]; then
    build_dir="$(sed -n 's/^buildDir="\(.*\)"$/\1/p' .qmlls.ini)"
fi
# Otherwise look for the tooling directory of a running instance of this shell.
if [[ -z $build_dir || ! -d $build_dir ]]; then
    for candidate in "${XDG_RUNTIME_DIR:-/run/user/$UID}"/quickshell/vfs/*/; do
        if [[ "$(readlink -f "$candidate/qs/shell.qml")" == "$root/shell.qml" ]]; then
            build_dir="${candidate%/}"
        fi
    done
fi
if [[ -z $build_dir || ! -d $build_dir ]]; then
    echo "No Quickshell tooling directory; run 'qs -p .' once first." >&2
    exit 1
fi

mapfile -t files < <(git ls-files --cached --others --exclude-standard -- '*.qml')

"$qt_bin/qmllint" -I "$build_dir" "${files[@]}"

status=0
for file in "${files[@]}"; do
    if ! "$qt_bin/qmlformat" -w 4 "$file" | diff -q - "$file" > /dev/null; then
        echo "needs formatting: $file" >&2
        status=1
    fi
done
exit $status
