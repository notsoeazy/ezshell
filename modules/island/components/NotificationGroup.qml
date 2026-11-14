pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.components
import qs.components.controls
import qs.services
import qs.modules.island

// The notifications of one app. With one it is just that notification, as a
// card. With more they share one card, whose rows run edge to edge so that a
// row's hover highlight fills it: a header with the app's name (and Clear for
// them all, and a chevron), the newest under it, then, closed, an "N more" row
// that opens the rest, or, open, the rest, each set off by a line.
Item {
    id: root

    required property string appName
    property bool expanded
    // Read live from the list, so a change to it updates this group in place
    // and does not rebuild it (which would close it).
    readonly property var items: Notifications.list.filter(n => n.appName === appName)
    readonly property bool grouped: items.length > 1
    // Whether the notification a click led here is one of these.
    readonly property bool holdsTarget: IslandState.focusedNotification.length > 0 && items.some(item => item.uid === IslandState.focusedNotification)

    signal revealed(item: Item)

    onHoldsTargetChanged: {
        if (holdsTarget)
            expanded = true;
    }
    Component.onCompleted: {
        if (holdsTarget)
            expanded = true;
    }

    implicitWidth: grouped ? shared.implicitWidth : single.implicitWidth
    implicitHeight: grouped ? shared.implicitHeight : single.implicitHeight

    // One notification: a card of its own.
    NotificationItem {
        id: single

        anchors.left: parent.left
        anchors.right: parent.right
        visible: !root.grouped
        notification: root.items[0] ?? null
        toggleOnClick: true
        onRevealed: item => root.revealed(item)
    }

    // Several: one card for all of them.
    ClippingRectangle {
        id: shared

        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.grouped
        implicitHeight: rows.implicitHeight
        radius: Tokens.radius.lg
        color: Theme.color.fillTertiary

        ColumnLayout {
            id: rows

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.spacing.md
                Layout.rightMargin: Tokens.spacing.md
                Layout.topMargin: Tokens.spacing.sm
                Layout.bottomMargin: Tokens.spacing.xs

                Label {
                    Layout.fillWidth: true
                    text: root.appName
                    emphasized: true
                    level: Label.Secondary
                }

                Button {
                    text: "Clear"
                    style: Button.Plain
                    size: Tokens.size.sm
                    onActivated: Notifications.clearApp(root.appName)
                }

                // Not the row's chevron: this opens and closes the whole group.
                IconButton {
                    icon: root.expanded ? "unfold_less" : "unfold_more"
                    style: Button.Plain
                    neutral: true
                    size: Tokens.size.sm
                    onActivated: root.expanded = !root.expanded
                }
            }

            Separator {
                Layout.fillWidth: true
            }

            NotificationItem {
                Layout.fillWidth: true
                framed: false
                padding: Tokens.spacing.md
                radius: 0
                toggleOnClick: true
                showApp: false
                notification: root.items[0] ?? null
                onRevealed: item => root.revealed(item)
            }

            // Closed: how many more there are, as a row that opens them.
            Item {
                Layout.fillWidth: true
                visible: !root.expanded
                implicitHeight: Tokens.control.xl

                Separator {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                }

                Label {
                    anchors.left: parent.left
                    anchors.leftMargin: Tokens.spacing.md
                    anchors.verticalCenter: parent.verticalCenter
                    text: `Show ${root.items.length - 1} more`
                    fontSize: Tokens.fontSize.sm
                    level: Label.Secondary
                }

                Pressable {
                    radius: 0
                    onActivated: root.expanded = true
                }
            }

            Reveal {
                Layout.fillWidth: true
                shown: root.expanded
                collapse: Reveal.Vertical

                ColumnLayout {
                    spacing: 0

                    Repeater {
                        // The same notification keeps its row, and so its open state.
                        model: ScriptModel {
                            values: root.items.slice(1)
                        }

                        ColumnLayout {
                            required property NotifData modelData

                            Layout.fillWidth: true
                            spacing: 0

                            Separator {
                                Layout.fillWidth: true
                            }

                            NotificationItem {
                                Layout.fillWidth: true
                                framed: false
                                padding: Tokens.spacing.md
                                radius: 0
                                toggleOnClick: true
                                showApp: false
                                notification: parent.modelData
                                onRevealed: item => root.revealed(item)
                            }
                        }
                    }
                }
            }
        }
    }
}
