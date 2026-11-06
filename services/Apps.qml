pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    readonly property list<DesktopEntry> entries: DesktopEntries.applications.values.filter(e => !e.noDisplay)
    // Lowest score that still contains the query (a keyword substring: 2 * 0.6); see Fuzzy.score.
    readonly property real minStrongScore: 1.2

    // Name matches beat generic-name matches, which beat keyword matches; ties sort by name.
    function relevance(query: string, entry: DesktopEntry): real {
        const name = Fuzzy.score(query, entry.name);
        const generic = Fuzzy.score(query, entry.genericName) * 0.8;
        const keywords = Fuzzy.score(query, entry.keywords) * 0.6;
        return Math.max(name, generic, keywords);
    }

    function search(query: string, limit: int): list<DesktopEntry> {
        const byName = (a, b) => a.name.localeCompare(b.name);
        const q = query.trim();
        if (q === "")
            return [...root.entries].sort(byName).slice(0, limit);
        const scored = root.entries.map(e => ({
                    entry: e,
                    score: root.relevance(q, e)
                })).filter(m => m.score > 0);
        scored.sort((a, b) => b.score - a.score || byName(a.entry, b.entry));
        // Loose in-order matches ("ffx") only count when nothing contains the query as written.
        const strong = scored.length > 0 && scored[0].score >= 2;
        const kept = strong ? scored.filter(m => m.score >= root.minStrongScore) : scored;
        return kept.slice(0, limit).map(m => m.entry);
    }

    function launch(entry: DesktopEntry): void {
        entry?.execute();
    }

    IpcHandler {
        function search(query: string): string {
            return root.search(query, 10).map(e => e.name).join("\n");
        }

        // Launches the best match, like pressing Enter in the launcher.
        function launch(query: string): void {
            root.launch(root.search(query, 1)[0] ?? null);
        }

        target: "apps"
    }
}
