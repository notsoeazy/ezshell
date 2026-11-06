pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.utils

// Emoji, symbols, kaomoji and Nerd Font glyphs from assets/emoji.tsv (scripts/emoji-gen.py), loaded once.
// Recent picks persist in ~/.local/state/ezshell/emoji.json; copying goes through Clipboard.
Singleton {
    id: root

    // { kind: e | s | k | n, text, name, words, font } in file order (font: a family for symbols and kaomoji
    // the UI font can't draw, "" otherwise), plus folded copies for search (lowercase,
    // no accents): foldedName, and folded (" name words", leading space so word starts are " " + query).
    readonly property var entries: internal.entries
    readonly property bool loaded: internal.entries.length > 0
    // Most recent first, as entries.
    readonly property var recents: root.recentTexts.map(text => internal.byText[text]).filter(e => e !== undefined)
    readonly property int maxRecents: 30
    // Ties sort emoji first, then symbols, kaomoji, and Nerd Font glyphs last (there are 10,000 of them).
    readonly property var kindOrder: ({
            e: 0,
            s: 1,
            k: 2,
            n: 3
        })

    // Picked texts, most recent first (emoji.json).
    property alias recentTexts: store.recent

    // Ranked: name starts with the query, a word in the name does, a search word does, then contains it;
    // emoji get a step up so they lead mixed results. Loose in-order matches (Fuzzy.score) only when
    // nothing contains the query, and not over the 10,000 Nerd Font names. Empty query: nothing.
    function search(query: string, limit: int): var {
        const q = Fuzzy.fold(query.trim());
        if (q === "")
            return [];
        const word = ` ${q}`;
        let scored = [];
        for (const entry of internal.entries) {
            if (!entry.folded.includes(q))
                continue;
            const name = entry.foldedName;
            const inName = name.startsWith(q) ? 4 : (` ${name}`).includes(word) ? 3 : 0;
            const base = inName > 0 ? inName : entry.folded.includes(word) ? 2.5 : 1.5;
            scored.push({
                entry: entry,
                score: base + (entry.kind === "e" ? 1 : 0)
            });
        }
        if (scored.length === 0)
            scored = internal.entries.filter(e => e.kind !== "n" && Fuzzy.score(q, e.foldedName) > 0).map(e => ({
                        entry: e,
                        score: 1
                    }));
        scored.sort((a, b) => b.score - a.score || root.kindOrder[a.entry.kind] - root.kindOrder[b.entry.kind]);
        return (limit > 0 ? scored.slice(0, limit) : scored).map(m => m.entry);
    }

    function copy(text: string): void {
        Clipboard.copyText(text);
        root.recentTexts = [text, ...root.recentTexts.filter(t => t !== text)].slice(0, root.maxRecents);
    }

    function parse(text: string): void {
        const entries = [];
        const byText = {};
        for (const line of text.split("\n")) {
            const [kind, value, name, words, font] = line.split("\t");
            if (!value)
                continue;
            const entry = {
                kind: kind,
                text: value,
                name: name,
                words: words ?? "",
                font: font ?? "",
                foldedName: Fuzzy.fold(name),
                folded: Fuzzy.fold(` ${name} ${words ?? ""}`)
            };
            entries.push(entry);
            byText[value] = entry;
        }
        internal.byText = byText;
        internal.entries = entries;
    }

    function describe(entries: var): string {
        return entries.map(e => `${e.text}\t${e.name}`).join("\n");
    }

    QtObject {
        id: internal

        property var entries: []
        property var byText: ({})
    }

    FileView {
        path: Quickshell.shellPath("assets/emoji.tsv")
        onLoaded: root.parse(text())
    }

    // Only this service writes it, so no watcher; the first pick creates it, and until then a missing file
    // is expected, not an error.
    FileView {
        path: `${Paths.state}/emoji.json`
        printErrors: false
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: store

            // Picked texts, most recent first.
            property list<string> recent: []
        }
    }

    IpcHandler {
        // The best 20 matches, "<text><TAB><name>" per line.
        function search(text: string): string {
            return root.describe(root.search(text, 20));
        }

        function copy(text: string): void {
            root.copy(text);
        }

        function recents(): string {
            return root.describe(root.recents);
        }

        target: "emoji"
    }
}
