import QtQuick
import qs.config
import qs.services
import qs.modules.island
import qs.modules.island.components

// A new notification, shown for a few seconds. Click the island to open the
// full list; it stays while the pointer is on it.
View {
    holdOnHover: true
    margin: Tokens.island.panelPadding

    // A fixed width, the same as the panels, however short the text is.
    Item {
        implicitWidth: Tokens.island.panelWidth
        implicitHeight: item.implicitHeight

        NotificationItem {
            id: item

            anchors.left: parent.left
            anchors.right: parent.right
            notification: Notifications.banner
            framed: false
            verticalExpand: true
        }
    }
}
