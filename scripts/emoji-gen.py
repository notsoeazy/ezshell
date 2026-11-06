#!/usr/bin/env python3
"""One-off generator for assets/emoji.tsv, the emoji picker's data. Run by hand, never by the shell:

    python3 -I scripts/emoji-gen.py

Sources, in caelestia's spirit:
  - emojibase compact.raw.json (MIT, names and tags from Unicode CLDR)
    https://raw.githubusercontent.com/milesj/emojibase/refs/heads/master/packages/data/en/compact.raw.json
  - Nerd Fonts glyphnames.json (MIT)
    https://raw.githubusercontent.com/ryanoasis/nerd-fonts/refs/heads/master/glyphnames.json
  - scripts/emoji-extra.tsv, hand-written symbols and kaomoji.

Output: kind<TAB>text<TAB>name<TAB>words<TAB>font, kind e (emoji), s (symbol), k (kaomoji) or n (Nerd Font
glyph). font names an installed family for symbols and kaomoji the UI font (Inter) can't draw, so the grid
asks for it directly: when Qt tries Inter for a complex script first (Kannada in ಠ_ಠ), it logs "OpenType
support missing" on every draw.
Anything the installed fonts can't draw is left out: emoji are checked against Noto Color Emoji,
including its ligatures for multi-character sequences (ZWJ, flags, keycaps); the rest against every
installed font. Needs fontTools and fontconfig (fc-list).
"""

import json
import pathlib
import subprocess
import sys
import unicodedata
from urllib.request import urlopen

from fontTools.ttLib import TTCollection, TTFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
EMOJIBASE = "https://raw.githubusercontent.com/milesj/emojibase/refs/heads/master/packages/data/en/compact.raw.json"
NERD = "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/refs/heads/master/glyphnames.json"
# Presentation selectors don't need a glyph of their own.
IGNORED = {0xFE0E, 0xFE0F}


def fetch(url):
    with urlopen(url) as response:
        return json.load(response)


def fonts(path):
    if path.lower().endswith((".ttc", ".otc")):
        return list(TTCollection(path, lazy=True).fonts)
    return [TTFont(path, lazy=True)]


UI_FONT = "Inter"


def families():
    """Code points per installed font family (the first family name fontconfig reports)."""
    listing = subprocess.run(["fc-list", "--format", "%{family[0]}\t%{file}\n"], capture_output=True, text=True)
    by_family = {}
    for line in sorted(set(listing.stdout.splitlines())):
        family, path = line.split("\t", 1)
        try:
            for font in fonts(path):
                by_family.setdefault(family, set()).update(font.getBestCmap() or {})
        except Exception as error:
            print(f"skipping {path}: {error}", file=sys.stderr)
    return by_family


# Scripts Qt shapes with OpenType: a family tried for one of these without support for it logs the message,
# so they decide the choice before plain coverage does.
COMPLEX = {"ARABIC", "BENGALI", "DEVANAGARI", "GUJARATI", "GURMUKHI", "KANNADA", "KHMER", "LAO", "MALAYALAM",
           "MYANMAR", "ORIYA", "SINHALA", "TAMIL", "TELUGU", "THAI", "TIBETAN"}


def font_for(cps, by_family):
    """"" when the UI font draws everything; else the family covering the complex-script characters, then most of
    the rest of what the UI font can't (Noto first)."""
    missing = set(cps) - by_family.get(UI_FONT, set())
    if not missing:
        return ""
    complex_chars = {cp for cp in missing if unicodedata.name(chr(cp), "").split(" ")[0] in COMPLEX}

    def rank(family):
        covered = by_family[family]
        return (len(complex_chars & covered), len(missing & covered), len(set(cps) & covered),
                family.startswith("Noto Sans"), -len(family))

    return max(by_family, key=rank)


def emoji_font():
    path = subprocess.run(["fc-match", "--format", "%{file}", "Noto Color Emoji"], capture_output=True, text=True).stdout
    font = TTFont(path)
    cmap = font.getBestCmap()
    by_glyph = {glyph: cp for cp, glyph in cmap.items()}
    sequences = set()
    for lookup in font["GSUB"].table.LookupList.Lookup:
        for sub in lookup.SubTable:
            sub = getattr(sub, "ExtSubTable", sub)
            for first, ligatures in getattr(sub, "ligatures", {}).items():
                for ligature in ligatures:
                    names = [first, *ligature.Component]
                    if all(n in by_glyph for n in names):
                        sequences.add(tuple(by_glyph[n] for n in names if by_glyph[n] not in IGNORED))
    return set(cmap), sequences


def codepoints(text):
    return tuple(ord(c) for c in text if ord(c) not in IGNORED)


def main():
    by_family = families()
    covered = set().union(*by_family.values())
    emoji_cmap, emoji_sequences = emoji_font()
    rows, dropped = [], {}

    def add(kind, text, name, words, drawable, font=""):
        if drawable:
            rows.append((kind, text, name, " ".join(w for w in words if w and w != name), font))
        else:
            dropped[kind] = dropped.get(kind, 0) + 1

    extra = ROOT / "scripts" / "emoji-extra.tsv"
    for line in extra.read_text().splitlines():
        if line and not line.startswith("#"):
            kind, text, name, words = line.split("\t")
            cps = codepoints(text)
            add(kind, text, name, words.split(), all(cp in covered for cp in cps), font_for(cps, by_family))

    for emoji in sorted(fetch(EMOJIBASE), key=lambda e: e.get("order", 1e9)):
        # Skin-tone components and lone regional indicators aren't picked on their own.
        if emoji.get("group") in (None, 2):
            continue
        cps = codepoints(emoji["unicode"])
        drawable = cps[0] in emoji_cmap if len(cps) == 1 else cps in emoji_sequences
        emoticon = emoji.get("emoticon", [])
        words = [*(emoticon if isinstance(emoticon, list) else [emoticon]), *emoji.get("tags", [])]
        add("e", emoji["unicode"], emoji["label"], words, drawable)

    glyphs = {}
    for name, glyph in fetch(NERD).items():
        if name != "METADATA":
            glyphs.setdefault(glyph["char"], []).append(f"nf-{name}")
    for char, names in glyphs.items():
        add("n", char, names[0], names[1:], ord(char) in covered)

    out = ROOT / "assets" / "emoji.tsv"
    out.write_text("".join("\t".join(row) + "\n" for row in rows))
    kinds = {k: sum(1 for r in rows if r[0] == k) for k in "eskn"}
    fonts_used = sorted({r[4] for r in rows if r[4]})
    print(f"wrote {len(rows)} rows to {out.relative_to(ROOT)}: {kinds}; left out (no glyph): {dropped}")
    print(f"symbols and kaomoji outside {UI_FONT}: {sum(1 for r in rows if r[4])}, in {fonts_used}")


if __name__ == "__main__":
    main()
