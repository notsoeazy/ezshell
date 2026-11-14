pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.island
import qs.modules.island.components

// Every notification, newest first, with Do Not Disturb and Clear.
View {
    dismissible: true
    margin: Tokens.island.panelPadding

    // Let the outline go after a moment.
    Timer {
        running: IslandState.focusedNotification.length > 0
        interval: Tokens.motion.highlight
        onTriggered: IslandState.focusedNotification = ""
    }

    // A fixed width, whatever the text: opening a notification wraps its text
    // onto more lines, it does not widen the list.
    Item {
        implicitWidth: Tokens.island.sheetContentWidth
        implicitHeight: column.implicitHeight

        ColumnLayout {
            id: column

            width: parent.width
            spacing: Tokens.spacing.md

            RowLayout {
                spacing: Tokens.spacing.sm

                Label {
                    Layout.fillWidth: true
                    text: "Notifications"
                    fontSize: Tokens.fontSize.lg
                    emphasized: true
                }

                ToggleButton {
                    icon: "notifications_off"
                    size: Tokens.size.lg
                    checked: ShellState.doNotDisturb
                    onActivated: ShellState.doNotDisturb = !ShellState.doNotDisturb
                }

                Button {
                    text: "Clear"
                    size: Tokens.size.lg
                    capsule: true
                    disabled: Notifications.count === 0
                    onActivated: Notifications.clear()
                }
            }

            Label {
                visible: Notifications.count === 0
                text: ShellState.doNotDisturb ? "No notifications. Do Not Disturb is on." : "No notifications."
                level: Label.Secondary
            }

            ScrollView {
                id: scroller

                // Scroll to an item (the notification a click led here).
                function revealItem(item: Item): void {
                    const y = item.mapToItem(contentItem, 0, 0).y;
                    contentY = Math.max(0, Math.min(contentHeight - height, y - Tokens.spacing.sm));
                }

                Layout.fillWidth: true
                // Grows with the list up to a limit, then scrolls.
                Layout.preferredHeight: Math.min(implicitHeight, Tokens.control.tile * 8)
                visible: Notifications.count > 0
                spacing: Tokens.spacing.sm

                Repeater {
                    // By app name, so a change to the list leaves the groups
                    // where they are and open.
                    model: ScriptModel {
                        values: Notifications.groupApps
                    }

                    NotificationGroup {
                        required property string modelData

                        Layout.fillWidth: true
                        appName: modelData
                        onRevealed: item => scroller.revealItem(item)
                    }
                }
            }
        }
    }
}
