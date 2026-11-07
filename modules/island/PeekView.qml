pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services
import qs.state
import qs.themes

// The hover peek's second line (docs/ISLAND-R1.md): optional date centered right under the clock,
// then the focused app on the left, a media chip in the center, notification status on the right.
Item {
    id: root

    required property string screenName
    readonly property var entry: Apps.entryFor(Hypr.activeAppId)
    readonly property string appName: root.entry?.name ?? Hypr.activeAppId
    readonly property bool showHoverDate: Config.island.showDate && Config.island.showDateOnHover
    readonly property int rowHeight: Appearance.island.height - Appearance.island.peek.bottomPadding

    implicitHeight: root.rowHeight + (root.showHoverDate ? Appearance.island.peek.dateRowHeight : 0)

    component Label: StyledText {
        font.pixelSize: Appearance.island.peek.text
    }

    StyledText {
        id: hoverDate

        visible: root.showHoverDate
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(Time.date, "dddd, d MMMM")
        color: Colors.surfaceVariantFg
        font.pixelSize: Appearance.font.size.small
        font.weight: Font.Medium
    }

    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.rowHeight

        RowLayout {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Appearance.spacing.normal

            IconImage {
                visible: root.entry !== null
                implicitSize: Appearance.island.peek.appIcon
                source: Quickshell.iconPath(root.entry?.icon ?? "", "application-x-executable")
            }

            Label {
                Layout.maximumWidth: Appearance.island.peek.appMaxWidth
                text: root.appName !== "" ? root.appName : "Desktop"
                elide: Text.ElideRight
                color: root.appName !== "" ? Colors.surfaceFg : Colors.surfaceVariantFg
                font.weight: Font.Medium
            }
        }

        // Media chip: the chip opens the Media tab, its button only plays or pauses.
        StyledRect {
            anchors.centerIn: parent
            visible: Players.active !== null
            implicitWidth: chip.implicitWidth + 2 * Appearance.island.peek.chipPadding + Appearance.spacing.small
            implicitHeight: Appearance.island.peek.chipArt + 2 * Appearance.island.peek.chipPadding
            radius: Appearance.island.peek.chipRadius
            color: Colors.surfaceContainer

            // Exclusive grab on press, so the island's own TapHandler doesn't open Control instead.
            TapHandler {
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: Visibility.openByPointer("media", root.screenName)
            }

            RowLayout {
                id: chip

                anchors.left: parent.left
                anchors.leftMargin: Appearance.island.peek.chipPadding
                anchors.verticalCenter: parent.verticalCenter
                spacing: Appearance.spacing.normal

                ClippingRectangle {
                    implicitWidth: Appearance.island.peek.chipArt
                    implicitHeight: Appearance.island.peek.chipArt
                    radius: Appearance.island.peek.chipArtRadius
                    color: Colors.surfaceContainerHighest

                    Image {
                        anchors.fill: parent
                        source: Players.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: Appearance.island.peek.chipArt
                        sourceSize.height: Appearance.island.peek.chipArt
                    }
                }

                ColumnLayout {
                    spacing: 0

                    Label {
                        Layout.maximumWidth: Appearance.island.peek.appMaxWidth
                        text: Players.title !== "" ? Players.title : Players.identity
                        elide: Text.ElideRight
                        font.weight: Font.DemiBold
                    }

                    Label {
                        Layout.maximumWidth: Appearance.island.peek.appMaxWidth
                        visible: text !== ""
                        text: Players.artist
                        elide: Text.ElideRight
                        color: Colors.surfaceVariantFg
                        font.pixelSize: Appearance.font.size.small
                    }
                }

                MaterialIcon {
                    text: Players.playing ? "pause" : "play_arrow"
                    fill: 1

                    // Exclusive grab on press, so the chip's TapHandler doesn't also open the Media tab.
                    TapHandler {
                        margin: Appearance.spacing.small
                        gesturePolicy: TapHandler.ReleaseWithinBounds
                        onTapped: Players.playPause()
                    }
                }
            }
        }

        // Notification status: opens Control at the notification center.
        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Appearance.spacing.small

            Label {
                text: Notifs.dnd ? "Do not disturb" : Notifs.count > 0 ? `${Notifs.count} new` : "All caught up"
                color: Notifs.count > 0 && !Notifs.dnd ? Colors.primary : Colors.surfaceVariantFg
            }

            MaterialIcon {
                text: Notifs.dnd ? "do_not_disturb_on" : Notifs.count > 0 ? "notifications_active" : "notifications"
                size: Appearance.font.size.large
                color: Notifs.count > 0 && !Notifs.dnd ? Colors.primary : Colors.surfaceVariantFg
            }

            // Exclusive grab on press, so the island's own TapHandler doesn't open plain Control.
            TapHandler {
                margin: Appearance.spacing.small
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: Visibility.openByPointer("notifications", root.screenName)
            }
        }
    }
}
