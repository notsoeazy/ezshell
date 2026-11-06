import QtQuick
import QtQuick.Layouts
import qs.components
import qs.themes

// Quick-toggle tile (frame 07). Tile rule (docs/ISLAND.md): the icon toggles; the body, the chevron
// or a right-click opens the detail section. Without `toggleable`, every click opens.
// `compact` (the Overview bento, frame 14): icon only; a left click toggles, a right click opens.
StyledRect {
    id: root

    property string icon: ""
    property string label: ""
    property string status: ""
    property bool active: false
    property bool toggleable: true
    property bool hasDetail: true
    property bool compact: false
    readonly property color foreground: root.active ? Colors.primaryContainerFg : Colors.surfaceFg

    signal toggled
    signal opened

    implicitHeight: root.compact ? Appearance.island.dashboard.compactTile : Appearance.island.expanded.tile
    radius: Appearance.island.expanded.tileRadius
    color: root.active ? Colors.primaryContainer : Colors.surfaceContainerHighest

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            const left = mouse.button === Qt.LeftButton;
            if (root.compact && left && root.toggleable)
                root.toggled();
            else if (root.hasDetail)
                root.opened();
            else if (left)
                root.toggled();
        }
    }

    MaterialIcon {
        anchors.centerIn: parent
        visible: root.compact
        text: root.icon
        fill: root.active ? 1 : 0
        color: root.foreground
    }

    RowLayout {
        anchors.fill: parent
        visible: !root.compact
        anchors.leftMargin: Appearance.spacing.large
        anchors.rightMargin: Appearance.spacing.normal
        spacing: Appearance.island.expanded.gap

        MaterialIcon {
            text: root.icon
            fill: root.active ? 1 : 0
            color: root.foreground

            MouseArea {
                anchors.fill: parent
                anchors.margins: -Appearance.spacing.normal
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (root.toggleable && mouse.button === Qt.LeftButton)
                        root.toggled();
                    else if (root.hasDetail)
                        root.opened();
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.label
                elide: Text.ElideRight
                color: root.foreground
                font.weight: Font.Medium
            }

            StyledText {
                Layout.fillWidth: true
                text: root.status
                elide: Text.ElideRight
                color: root.foreground
                opacity: Appearance.island.expanded.secondaryOpacity
                font.pixelSize: Appearance.font.size.small
            }
        }

        MaterialIcon {
            visible: root.hasDetail
            text: "chevron_right"
            color: root.foreground
        }
    }
}
