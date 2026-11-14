import QtQuick
import qs.config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.island
import qs.modules.island.components

// Just the clock, always in the middle. A recording's dot sits on its left and
// the notification bell on its right.
View {
    // As tall as a row of status icons, so the island keeps its height when
    // it widens into `default`.
    Item {
        implicitWidth: row.implicitWidth + Tokens.island.paddingX * 2
        implicitHeight: Tokens.island.height - Tokens.island.paddingY * 2

        CenteredRow {
            id: row

            anchors.centerIn: parent
            
            leading: RecordingIndicator {}

            // Notification Indicator
            trailing: Reveal {
                shown: Notifications.count > 0
                collapse: Reveal.Horizontal
                fromScale: 0.6

                Icon {
                    name: "notifications"
                    filled: true
                    size: Tokens.icon.sm
                }
            }

            Clock {}
        }
    }
}
