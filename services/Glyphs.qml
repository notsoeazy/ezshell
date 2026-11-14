pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Emoji, symbols and Nerd Font glyphs, searched by name for the launcher.
// The list is assets/symbols.tsv (see scripts/fetch-symbols.py); it is read
// and indexed the first time something searches.
//
// Search works like fuzzel's: the query is split into words and every word has
// to match. A word matches as a whole word, the start of a word or anywhere
// inside (best first); only when nothing matches that way are the letters
// allowed to be spread out. Typing more of a query searches only what the
// shorter one found.
Singleton {
    id: root

    // The list is plain objects: { glyph, title, group, nerd, name, words, bonus }.
    //   nerd   whether it needs the Nerd Font to be drawn
    //   name   the title, lower case, words split on - and _; words, the extra
    //          search words the same way
    //   bonus  a small head start for the kinds people look for most

    readonly property FileView file: FileView {
        path: Quickshell.shellPath("assets/symbols.tsv")
        blockLoading: true
    }

    // Built on first use, with the last search's matches (kept to narrow the
    // next search). A plain object, so that changing it inside a binding that
    // calls `search` is not a binding loop.
    readonly property var state: ({
            entries: null,
            query: "",
            matches: null
        })

    function load(): void {
        const list = [];
        for (const line of file.text().split("\n")) {
            if (line.length === 0)
                continue;
            const [glyph, title, group, words] = line.split("\t");
            const nerd = group.startsWith("Nerd Font");
            list.push({
                glyph: glyph,
                title: title,
                group: group,
                nerd: nerd,
                // The name, and the extra search words, lower case, with - and _
                // read as spaces. The name counts for far more than the words.
                name: title.toLowerCase().replace(/[-_]/g, " "),
                words: (words ?? "").toLowerCase().replace(/[-_]/g, " "),
                bonus: group === "Symbols" ? 8 : nerd ? 0 : 5
            });
        }
        state.entries = list;
    }

    // How well `word` is in `text`: 3 as a whole word, 2 at the start of a
    // word, 1 inside one, 0 not at all. `first` is whether the whole word is
    // the first word of the text.
    function occurrence(text: string, word: string): var {
        let best = 0;
        let first = false;
        for (let at = text.indexOf(word); at >= 0; at = text.indexOf(word, at + 1)) {
            const starts = at === 0 || text[at - 1] === " ";
            const end = at + word.length;
            const ends = end === text.length || text[end] === " ";
            const level = starts && ends ? 3 : starts ? 2 : 1;
            if (level > best) {
                best = level;
                first = at === 0;
            }
        }
        return {
            level: best,
            first: first
        };
    }

    // Score of one query word for one entry, or 0 for no match. A match in the
    // name beats any match in the search words: the name itself (1000), a name
    // that starts with the word (600), the word anywhere in it (400), the start
    // of one of its words (250), inside one (120); then the words: whole word
    // (60), start (40), inside (20).
    function wordScore(entry: var, word: string): real {
        if (entry.name === word)
            return 1000;

        const inName = occurrence(entry.name, word);
        if (inName.level > 0)
            return inName.level === 3 ? (inName.first ? 600 : 400) : inName.level === 2 ? 250 : 120;

        return [0, 20, 40, 60][occurrence(entry.words, word).level];
    }

    // Letters in order, anywhere: the last resort.
    function spread(hay: string, word: string): bool {
        let position = 0;
        for (const letter of word) {
            position = hay.indexOf(letter, position);
            if (position < 0)
                return false;
            position++;
        }
        return true;
    }

    // The best `limit` entries for `query`, as { title, subtitle, glyph, nerd }.
    function search(query: string, limit: int): list<var> {
        if (state.entries === null)
            load();

        const entries = state.entries;

        const words = query.toLowerCase().trim().split(/\s+/).filter(word => word.length > 0);
        if (words.length === 0) {
            state.query = "";
            state.matches = null;
            return entries.slice(0, limit).map(shape);
        }

        const text = words.join(" ");
        // Nerd Font glyphs are the bulk of the list and rarely what an emoji search
        // wants, so they rank behind emoji unless the search is for them ("nf ...").
        const wantsNerd = words.some(word => word.startsWith("nf"));
        // A longer query can only match what the shorter one matched.
        const narrowed = state.matches !== null && state.query.length > 0 && text.startsWith(state.query);
        const pool = narrowed ? state.matches : null;
        const count = pool ? pool.length : entries.length;

        const matches = [];
        const scores = [];
        for (let n = 0; n < count; n++) {
            const index = pool ? pool[n] : n;
            const entry = entries[index];
            let total = 0;
            for (const word of words) {
                const score = wordScore(entry, word);
                if (score === 0) {
                    total = 0;
                    break;
                }
                total += score;
            }
            if (total === 0)
                continue;

            // The whole query, in order, in the name ("red heart"): a better match
            // than the words being somewhere in it.
            if (words.length > 1 && entry.name.indexOf(text) >= 0)
                total += 200;
            matches.push(index);
            // Shorter names first among equals; the list's own order (the common
            // emoji first) after that.
            scores[index] = total + entry.bonus - (entry.nerd && !wantsNerd ? 150 : 0) - Math.min(30, entry.name.length * 0.3);
        }

        if (matches.length > 0) {
            state.query = text;
            state.matches = matches;
            return matches.sort((a, b) => scores[b] - scores[a] || a - b).slice(0, limit).map(index => shape(entries[index]));
        }

        // Nothing matched whole: allow spread-out letters, never narrowed.
        state.query = "";
        state.matches = null;
        const loose = entries.filter(entry => words.every(word => word.length > 1 && spread(`${entry.name} ${entry.words}`, word)));
        return loose.slice(0, limit).map(shape);
    }

    function shape(entry: var): var {
        return {
            title: entry.title,
            subtitle: entry.group,
            glyph: entry.glyph,
            nerd: entry.nerd
        };
    }
}
