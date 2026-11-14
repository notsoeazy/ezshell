#!/usr/bin/env python3
"""Writes assets/symbols.tsv, the list the launcher's symbol mode searches.

One entry per line: the character, a tab, its name, a tab, its group, a tab,
extra search words. It joins three sources, as Caelestia's `caelestia emoji
--fetch` does:

  - emoji, with search tags and emoticons, from emojibase;
  - Nerd Font glyphs and their names, from the nerd-fonts glyphnames.json
    (the same version as the vendored Symbols Nerd Font, see fetch-fonts.sh);
  - a short hand-written list of everyday symbols.

Needs only the standard library. Run again to update; the output is committed.
"""

import json
import re
import sys
import urllib.request
from pathlib import Path

NERD_VERSION = "v3.4.0"
EMOJI = "https://raw.githubusercontent.com/milesj/emojibase/refs/heads/master/packages/data/en/compact.raw.json"
NERD = f"https://raw.githubusercontent.com/ryanoasis/nerd-fonts/refs/tags/{NERD_VERSION}/glyphnames.json"
TARGET = Path(__file__).resolve().parent.parent / "assets" / "symbols.tsv"

EMOJI_GROUPS = {
    0: "Smileys & Emotion",
    1: "People & Body",
    3: "Animals & Nature",
    4: "Food & Drink",
    5: "Travel & Places",
    6: "Activities",
    7: "Objects",
    8: "Symbols",
    9: "Flags",
}

NERD_SETS = {
    "cod": "Codicons",
    "custom": "Custom",
    "dev": "Devicons",
    "fa": "Font Awesome",
    "fae": "Font Awesome Extension",
    "iec": "IEC Power Symbols",
    "indent": "Indent",
    "linux": "Font Logos",
    "md": "Material Design",
    "oct": "Octicons",
    "pl": "Powerline",
    "ple": "Powerline Extra",
    "pom": "Pomicons",
    "seti": "Seti-UI",
    "weather": "Weather Icons",
}

EXTRAS = [
    ("¿", "inverted question mark", "question upside down reversed spanish"),
    ("¡", "inverted exclamation mark", "upside down reversed spanish"),
    ("←", "left arrow", ""),
    ("↑", "up arrow", ""),
    ("→", "right arrow", ""),
    ("↓", "down arrow", ""),
    ("↔", "left right arrow", "horizontal"),
    ("↕", "up down arrow", "vertical"),
    ("⇐", "leftwards double arrow", "implied by"),
    ("⇒", "rightwards double arrow", "implies"),
    ("⇔", "left right double arrow", "if and only if iff equivalent"),
    ("↵", "enter key", "return carriage"),
    ("⌘", "command key", "mac cmd"),
    ("⌥", "option key", "mac alt"),
    ("⇧", "shift key", ""),
    ("⌃", "control key", "ctrl"),
    ("•", "bullet", "dot circle separator"),
    ("·", "middle dot", "interpunct separator"),
    ("…", "ellipsis", "dots"),
    ("—", "em dash", "long dash"),
    ("–", "en dash", "range"),
    ("°", "degrees", "degree sign temperature"),
    ("±", "plus minus", ""),
    ("×", "multiplication sign", "times multiply"),
    ("÷", "division sign", "divide"),
    ("≠", "not equal to", ""),
    ("≈", "almost equal to", "approximately"),
    ("≤", "less than or equal to", ""),
    ("≥", "greater than or equal to", ""),
    ("∞", "infinity", ""),
    ("√", "square root", ""),
    ("π", "pi", "greek"),
    ("µ", "micro sign", "mu greek"),
    ("™", "trademark", "tm"),
    ("®", "registered trademark", ""),
    ("©", "copyright", ""),
    ("€", "euro", "currency"),
    ("£", "pound", "currency sterling"),
    ("¥", "yen", "currency"),
    ("₱", "peso", "currency philippine"),
    ("「」", "japanese quote brackets", "square corner"),
    ("¯\\_(ツ)_/¯", "shrug", "idk i dont know"),
    ("(╯°□°)╯︵ ┻━┻", "table flip", "angry rage"),
]


def fetch(url: str) -> object:
    with urllib.request.urlopen(url, timeout=60) as response:
        return json.load(response)


def clean(text: str) -> str:
    return re.sub(r"[\t\n]", " ", text).strip()


def main() -> int:
    lines = []

    for glyph, name, words in EXTRAS:
        lines.append(f"{glyph}\t{name}\tSymbols\t{words}")

    emoji = fetch(EMOJI)
    count = 0
    for entry in sorted(emoji, key=lambda e: e.get("order", 1 << 30)):
        group = EMOJI_GROUPS.get(entry.get("group", -1))
        if group is None:
            continue
        words = list(entry.get("tags", []))
        emoticon = entry.get("emoticon", [])
        words += [emoticon] if isinstance(emoticon, str) else emoticon
        lines.append(f"{entry['unicode']}\t{clean(entry['label'])}\t{group}\t{clean(' '.join(words))}")
        count += 1

    glyphs = fetch(NERD)
    by_char: dict[str, list[str]] = {}
    for name, glyph in glyphs.items():
        if name != "METADATA":
            by_char.setdefault(glyph["char"], []).append(name)
    for char, names in by_char.items():
        prefix = names[0].split("-", 1)[0]
        lines.append(f"{char}\tnf-{names[0]}\tNerd Font, {NERD_SETS.get(prefix, prefix)}\t{' '.join('nf-' + n for n in names[1:])}")

    TARGET.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"{len(EXTRAS)} symbols, {count} emoji, {len(by_char)} Nerd Font glyphs -> {TARGET.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
