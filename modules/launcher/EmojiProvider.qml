import QtQuick
import qs.services
import qs.state
import qs.themes

// ":" emoji, symbols, kaomoji and Nerd Font glyphs (caelestia's set), as a grid. Nothing typed: recent
// picks first, then everything. Chips filter by kind. Enter copies (paste with Ctrl+V), says so in the
// footer for a moment, then closes the launcher.
Provider {
    id: root

    // The glyph just copied, shown in the footer until the launcher closes.
    property string copied: ""
    // Long enough to read "Copied", then the launcher closes. An animation, not a Timer: UI only.
    property SequentialAnimation closing: SequentialAnimation {
        PauseAnimation {
            duration: Appearance.anim.scaled(Appearance.anim.copied)
        }

        ScriptAction {
            script: Visibility.close()
        }
    }
    readonly property var kinds: ({
            "Emoji": "e",
            "Symbols": "s",
            "Kaomoji": "k",
            "Nerd Font": "n"
        })
    // One cell object per entry, made once, so the grid's model keeps its items between searches.
    readonly property var cells: root.makeCells(Emoji.entries)
    // Browsing order: emoji, symbols, kaomoji, Nerd Font glyphs, each in file order (search ranks its own).
    readonly property var browse: [].concat(...["e", "s", "k", "n"].map(kind => root.ofKind(kind)))

    function ofKind(kind: string): var {
        return Emoji.entries.filter(e => e.kind === kind).map(e => root.cells[e.text]);
    }

    function makeCells(entries: var): var {
        const cells = {};
        for (const entry of entries)
            cells[entry.text] = {
                key: entry.text,
                glyph: entry.text,
                name: entry.name,
                kind: entry.kind,
                font: entry.kind === "e" ? Appearance.font.emoji : entry.font || undefined
            };
        return cells;
    }

    function matches(query: string, chip: string): var {
        const recent = Emoji.recents.map(e => root.cells[e.text]);
        if (chip === "Recent")
            return recent;
        const pool = query.trim() === "" ? root.browse : Emoji.search(query, 0).map(e => root.cells[e.text]);
        const kind = root.kinds[chip];
        const filtered = kind ? pool.filter(c => c.kind === kind) : pool;
        // All, nothing typed: recent picks lead, and aren't repeated below them.
        if (chip !== "All" || query.trim() !== "")
            return filtered;
        const seen = new Set(recent.map(c => c.key));
        return [...recent, ...filtered.filter(c => !seen.has(c.key))];
    }

    function status(item: var): string {
        return root.copied !== "" ? `Copied ${root.copied}` : item.name;
    }

    prefix: ":"
    name: "emoji"
    icon: "mood"
    layout: "grid"
    // Kaomoji are wide: their own chip gets wide cells so they're readable; elsewhere they're cut short.
    cellWidth: root.chip === "Kaomoji" ? Appearance.island.launcher.wideCell : Appearance.island.launcher.cell
    chips: ["All", "Recent", "Emoji", "Symbols", "Kaomoji", "Nerd Font"]
    chip: "All"
    emptyText: root.chip === "Recent" ? "Nothing picked yet" : "No matches"
    hints: "←↑↓→ move    ⏎ copy    tab category    esc close"
    items: root.current ? root.matches(root.query, root.chip) : []
    onCurrentChanged: {
        root.copied = "";
        root.chip = "All";
    }
    onActivated: item => {
        Emoji.copy(item.glyph);
        root.copied = item.glyph;
        closing.restart();
    }
}
