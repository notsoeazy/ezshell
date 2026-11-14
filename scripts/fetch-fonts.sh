#!/usr/bin/env bash
# Downloads the vendored fonts into assets/fonts/ at pinned versions. The icon
# font is not vendored: it comes from the package ttf-material-symbols-variable.
# Re-run after changing a version. The Nerd Font version must match
# NERD_VERSION in fetch-symbols.py, which names the glyphs.
set -euo pipefail

GEIST_VERSION="v1.9.2"
NERD_VERSION="v3.4.0"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$root/assets/fonts"
geist="https://raw.githubusercontent.com/vercel/geist-font/$GEIST_VERSION"

fetch() {
    echo "  $2"
    curl --fail --silent --show-error --location --output "$out/$2" "$1"
}

mkdir -p "$out/Geist"

echo "Geist $GEIST_VERSION"
fetch "$geist/fonts/Geist/variable/Geist%5Bwght%5D.ttf" "Geist/Geist-Variable.ttf"
fetch "$geist/fonts/GeistMono/variable/GeistMono%5Bwght%5D.ttf" "Geist/GeistMono-Variable.ttf"
fetch "$geist/OFL.txt" "Geist/LICENSE.txt"

echo "Symbols Nerd Font $NERD_VERSION"
mkdir -p "$out/NerdSymbols"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl --fail --silent --show-error --location --output "$tmp/symbols.zip" \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/$NERD_VERSION/NerdFontsSymbolsOnly.zip"
unzip -q -o -j "$tmp/symbols.zip" "SymbolsNerdFont-Regular.ttf" "LICENSE" -d "$out/NerdSymbols"
echo "  NerdSymbols/SymbolsNerdFont-Regular.ttf"
