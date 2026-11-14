pragma Singleton

import QtQuick
import Quickshell
import qs.config
import qs.utils

// Installed applications: the list, searching it, and launching.
Singleton {
    id: root

    readonly property list<DesktopEntry> list: DesktopEntries.applications.values.filter(app => !app.noDisplay).sort((a, b) => a.name.localeCompare(b.name))

    // The desktop entry for a window's class (or its first class), if there is
    // one. Reading the list first makes whatever calls this look again once
    // the list has loaded, which happens a moment after the first read.
    function entryFor(appClass: string, initialClass: string): var {
        const loaded = DesktopEntries.applications.values.length;
        if (loaded === 0)
            return null;
        return (appClass.length > 0 ? DesktopEntries.heuristicLookup(appClass) : null) ?? (initialClass.length > 0 ? DesktopEntries.heuristicLookup(initialClass) : null) ?? null;
    }

    function icon(app: DesktopEntry): string {
        return Quickshell.iconPath(app.icon, true);
    }

    // Best matches first. Apps launched more often rank higher among equals,
    // and with no query the most used come first.
    function search(query: string): list<DesktopEntry> {
        const usage = ShellState.appUsage;
        return list.map(app => ({
                    app: app,
                    score: Fuzzy.best(query, [app.name, app.genericName, app.keywords], [1, 0.7, 0.5]),
                    used: usage[app.id] ?? 0
                })).filter(match => match.score > 0).sort((a, b) => (b.score - a.score) || (b.used - a.used) || a.app.name.localeCompare(b.app.name)).map(match => match.app);
    }

    function launch(app: DesktopEntry): void {
        const usage = Object.assign({}, ShellState.appUsage);
        usage[app.id] = (usage[app.id] ?? 0) + 1;
        ShellState.appUsage = usage;
        app.execute();
    }
}
