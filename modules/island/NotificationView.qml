import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.components
import qs.services
import qs.themes

// Banner for the newest notification (docs/design/06-notification.png). Click runs its default action.
Item {
    id: root

    readonly property Notification notification: Notifs.latest
    readonly property string appIcon: root.notification?.appIcon ?? ""
    readonly property string iconSource: root.resolveIcon()
    readonly property real contentHeight: row.implicitHeight + 2 * Appearance.island.notification.padding

    function resolveIcon(): string {
        if (root.notification?.image)
            return root.notification.image;
        if (root.appIcon.startsWith("/"))
            return `file://${root.appIcon}`;
        return root.appIcon.includes("://") ? root.appIcon : Quickshell.iconPath(root.appIcon, true);
    }

    implicitWidth: Appearance.island.notification.width
    implicitHeight: Math.min(root.contentHeight, Appearance.island.notification.maxHeight)

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Notifs.activate(root.notification)
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.margins: Appearance.island.notification.padding
        spacing: Appearance.island.notification.gap

        ClippingRectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: Appearance.island.notification.icon
            implicitHeight: Appearance.island.notification.icon
            radius: Appearance.island.notification.iconRadius
            color: Colors.primaryContainer

            IconImage {
                anchors.fill: parent
                visible: root.iconSource !== ""
                source: root.iconSource
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: root.iconSource === ""
                text: "chat"
                color: Colors.primaryContainerFg
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 0

            StyledText {
                text: `${root.notification?.appName ?? ""} · now`
                color: Colors.surfaceVariantFg
                font.pixelSize: Appearance.font.size.small
                font.weight: Font.Medium
            }

            StyledText {
                Layout.fillWidth: true
                text: root.notification?.summary ?? ""
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.size.title
                font.weight: Font.DemiBold
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notification?.body ?? ""
                wrapMode: Text.Wrap
                maximumLineCount: Appearance.island.notification.bodyLines
                elide: Text.ElideRight
            }
        }

        MaterialIcon {
            Layout.alignment: Qt.AlignTop
            text: "close"
            size: Appearance.font.size.large
            color: Colors.surfaceVariantFg

            MouseArea {
                anchors.fill: parent
                anchors.margins: -Appearance.spacing.small
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifs.dismiss(root.notification)
            }
        }
    }
}
