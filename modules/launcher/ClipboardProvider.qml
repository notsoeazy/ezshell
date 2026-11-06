import QtQuick
import qs.services
import qs.state

// ";" clipboard history, newest first. Enter copies (paste with Ctrl+V), Delete removes an entry, and
// "Clear history" at the end takes a second Enter. Images show a thumbnail decoded for visible rows only.
Provider {
    id: root

    // True after the first Enter on "Clear history".
    property bool armed: false

    function matches(query: string): var {
        const q = query.trim().toLowerCase();
        const all = Clipboard.entries;
        return (q === "" ? all : all.filter(e => e.preview.toLowerCase().includes(q))).map(root.row);
    }

    function row(entry: var): var {
        return {
            key: entry.id,
            id: entry.id,
            icon: entry.image ? "image" : "content_paste",
            title: entry.image ? "Image" : entry.preview,
            subtitle: entry.image ? `${entry.format.toUpperCase()} · ${entry.width}×${entry.height} · ${entry.size}` : "",
            isImage: entry.image
        };
    }

    function clearRow(): var {
        return {
            key: "clear",
            icon: "delete_sweep",
            title: "Clear history",
            subtitle: root.armed ? `Press Enter again to delete all ${Clipboard.entries.length} entries` : "",
            clear: true
        };
    }

    // "Clear history" shows with the full list, or when the query matches it.
    function withClear(rows: var): var {
        const q = root.query.trim().toLowerCase();
        return q === "" || "clear history".includes(q) ? [...rows, root.clearRow()] : rows;
    }

    // Asking for a decode from a binding: deferred (one closure per row, since callLater merges repeat
    // calls of the same function), and a no-op once queued or done.
    function preview(item: var): string {
        if (!item.isImage)
            return "";
        if (!Clipboard.thumbs[item.id])
            Qt.callLater(() => Clipboard.thumbnail(item.id));
        return Clipboard.thumbs[item.id] ?? "";
    }

    prefix: ";"
    name: "clipboard"
    icon: "content_paste"
    emptyText: Clipboard.loading ? "Loading…" : "Clipboard history is empty"
    hints: "↑↓ navigate    ⏎ copy    del remove    esc close"
    removable: true
    items: root.current ? root.withClear(root.matches(root.query)) : []
    // Opening the list re-reads the history: Hyprland records copies, so it may have changed.
    onCurrentChanged: {
        root.armed = false;
        if (root.current)
            Clipboard.refresh();
    }
    onQueryChanged: root.armed = false
    onActivated: item => {
        if (item.clear && !root.armed) {
            root.armed = true;
            return;
        }
        if (item.clear)
            Clipboard.wipe();
        else
            Clipboard.copy(item.id);
        Visibility.close();
    }
    onRemoved: item => {
        if (!item.clear)
            Clipboard.remove(item.id);
    }
}
