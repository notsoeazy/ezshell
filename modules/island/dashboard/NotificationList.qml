pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.components
import qs.services
import qs.themes

// Notifications sub-page, pushed from the Overview summary. Newest first; click runs the default action.
ColumnLayout {
    id: root

    spacing: Appearance.island.expanded.gap

    RowLayout {
        Layout.fillWidth: true

        StyledText {
            Layout.fillWidth: true
            text: Notifs.count > 0 ? `${Notifs.count} notifications` : "No notifications"
            color: Colors.surfaceVariantFg
        }

        StyledButton {
            enabled: Notifs.count > 0
            text: "Clear all"
            icon: "clear_all"
            onClicked: Notifs.clear()
        }
    }

    ListView {
        Layout.fillWidth: true
        implicitHeight: Math.min(contentHeight, Appearance.island.expanded.listMaxHeight)
        clip: true
        spacing: Appearance.spacing.small
        boundsBehavior: Flickable.StopAtBounds
        model: ScriptModel {
            values: [...Notifs.list].reverse()
        }

        delegate: StyledRect {
            id: item

            required property Notification modelData

            width: ListView.view.width
            implicitHeight: Appearance.island.dashboard.notificationRow
            radius: Appearance.island.expanded.cardRadius
            color: Colors.surfaceContainerHigh

            TapHandler {
                onTapped: Notifs.activate(item.modelData)
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: Appearance.island.expanded.gap
                spacing: Appearance.island.expanded.gap

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: `${item.modelData?.appName ?? ""} · ${item.modelData?.summary ?? ""}`
                        elide: Text.ElideRight
                        font.weight: Font.Medium
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: item.modelData?.body ?? ""
                        elide: Text.ElideRight
                        color: Colors.surfaceVariantFg
                    }
                }

                MaterialIcon {
                    text: "close"
                    color: Colors.surfaceVariantFg

                    TapHandler {
                        margin: Appearance.spacing.small
                        gesturePolicy: TapHandler.ReleaseWithinBounds
                        onTapped: Notifs.dismiss(item.modelData)
                    }
                }
            }
        }
    }
}
