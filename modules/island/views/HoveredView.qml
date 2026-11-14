pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.island
import qs.modules.island.components

// Shown while the pointer rests on the island. Three columns, as in `default`
// and `idle`, over two rows:
//
//   the focused app        the time           notifications
//   logo, workspaces       the date           status icons
//
// Below them the media controls, when a player is active, and the latest
// notifications under a title of their own. The width is fixed, so the island
// only ever grows taller, and the columns have room between them.
View {
    margin: Tokens.island.panelPadding

    // A fixed width, whatever the text inside is: a long track title or
    // notification is cut short with an ellipsis, it does not widen the island.
    Item {
        implicitWidth: Tokens.island.sheetContentWidth
        implicitHeight: root.implicitHeight

        ColumnLayout {
            id: root

            width: parent.width

            // The height of each row, the same in every column so that they line up.
            readonly property real topHeight: Math.max(clock.implicitHeight, app.implicitHeight, summary.implicitHeight)
            // The full date ("Saturday, November 14") when the columns on either
            // side leave room for it, else the short one ("Sat, Nov 14"): with
            // many workspace dots the left column is wide.
            readonly property real bottomHeight: Math.max(date.implicitHeight, dots.implicitHeight, status.implicitHeight)

            // The space between the two rows, the same in every column so that
            // they line up.
            readonly property real rowGap: Tokens.spacing.sm

            // Whether the notifications section is there: see
            // `island.hoveredNotifications`.
            readonly property bool showNotifications: Config.island.hoveredNotifications === "always" || (Config.island.hoveredNotifications === "whenAny" && Notifications.count > 0)

            spacing: Tokens.spacing.md

            CenteredRow {
                id: header

                Layout.fillWidth: true
                Layout.preferredWidth: Tokens.island.sheetContentWidth

                leading: ColumnLayout {
                    id: leadingCol

                    spacing: root.rowGap

                    Item {
                        Layout.fillWidth: true
                        implicitWidth: app.implicitWidth
                        implicitHeight: root.topHeight

                        ActiveWindow {
                            id: app

                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitWidth: leadingBottom.implicitWidth
                        implicitHeight: root.bottomHeight

                        RowLayout {
                            id: leadingBottom

                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Tokens.spacing.sm

                            Logo {}

                            Workspaces {
                                id: dots

                                contained: false
                            }

                            RecordingIndicator {
                                Layout.leftMargin: Tokens.spacing.sm
                            }
                        }
                    }
                }

                trailing: ColumnLayout {
                    id: trailingCol

                    spacing: root.rowGap

                    Item {
                        Layout.fillWidth: true
                        implicitWidth: summary.implicitWidth
                        implicitHeight: root.topHeight

                        NotificationSummary {
                            id: summary

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitWidth: status.implicitWidth
                        implicitHeight: root.bottomHeight

                        StatusIcons {
                            id: status

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // The middle column: click the time or the date for the calendar.
                Item {
                    implicitWidth: middle.implicitWidth
                    implicitHeight: middle.implicitHeight

                    ColumnLayout {
                        id: middle

                        spacing: 0

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: clock.implicitWidth
                            implicitHeight: root.topHeight

                            Clock {
                                id: clock

                                anchors.centerIn: parent
                                fontSize: Tokens.fontSize.xl
                                weight: Tokens.fontWeight.bold
                            }
                        }

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: date.implicitWidth
                            implicitHeight: root.bottomHeight

                            Label {
                                id: date

                                anchors.centerIn: parent
                                text: Time.format("ddd, MMM d")
                                fontSize: Tokens.fontSize.sm
                                level: Label.Secondary
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: IslandState.open("calendar")
                    }
                }
            }

            Separator {
                Layout.fillWidth: true
                visible: Media.available || root.showNotifications
            }

            Reveal {
                Layout.fillWidth: true
                shown: Media.available
                collapse: Reveal.Vertical

                Card {
                    Layout.fillWidth: true

                    MediaControls {
                        anchors.left: parent.left
                        anchors.right: parent.right
                    }
                }
            }

            // The notifications, under a title of their own so they do not read as
            // part of the media above. `island.hoveredNotifications` sets whether
            // the section is always there, only while there are notifications, or
            // never; with none and "always", a card says so.
            Reveal {
                Layout.fillWidth: true
                shown: root.showNotifications
                collapse: Reveal.Vertical

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.sm

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            Layout.fillWidth: true
                            text: "Notifications"
                            fontSize: Tokens.fontSize.sm
                            emphasized: true
                            level: Label.Secondary
                        }

                        Button {
                            visible: Notifications.count > 0
                            text: "Show all"
                            style: Button.Plain
                            size: Tokens.size.sm
                            onActivated: IslandState.open("notifications")
                        }
                    }

                    Card {
                        Layout.fillWidth: true
                        visible: Notifications.count === 0

                        Item {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            implicitHeight: Tokens.control.xl

                            Label {
                                anchors.centerIn: parent
                                text: "All caught up!"
                                level: Label.Secondary
                            }
                        }
                    }

                    // The latest three, plain: no groups, those are in the list.
                    Repeater {
                        // Two while a track is showing, so the island stays short.
                        model: ScriptModel {
                            values: Notifications.list.slice(0, Media.available ? 2 : 3)
                        }

                        NotificationItem {
                            required property NotifData modelData

                            Layout.fillWidth: true
                            notification: modelData
                            clickable: true
                            verticalExpand: true
                            padding: Tokens.spacing.sm
                            onOpened: IslandState.openNotification(modelData.uid)
                        }
                    }
                }
            }
        }
    }
}
