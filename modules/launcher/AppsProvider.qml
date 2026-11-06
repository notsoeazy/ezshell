import QtQuick
import Quickshell
import qs.services
import qs.state
import qs.themes

// Desktop apps, the default provider (no prefix).
Provider {
    id: root

    function row(entry: DesktopEntry): var {
        return {
            key: entry.id,
            title: entry.name,
            subtitle: entry.comment || entry.genericName,
            image: entry.icon,
            entry: entry
        };
    }

    name: "apps"
    emptyText: "No matching apps"
    items: root.current ? Apps.search(root.query, Appearance.island.launcher.maxResults).map(root.row) : []
    onActivated: item => {
        Apps.launch(item.entry);
        Visibility.close();
    }
}
