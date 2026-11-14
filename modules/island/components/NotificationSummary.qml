import QtQuick
import qs.config
import qs.components
import qs.services
import qs.modules.island

// How many notifications are waiting, with a bell: "All caught up" when none.
// Click it for the list.
HeaderChip {
    id: root

    readonly property int count: Notifications.count

    onActivated: IslandState.open("notifications")

    Label {
        text: root.count === 0 ? "All caught up" : root.count === 1 ? "1 notification" : `${root.count} notifications`
        fontSize: Tokens.fontSize.md
    }

    Icon {
        name: "notifications"
        size: Tokens.icon.sm
        filled: root.count > 0
    }
}
