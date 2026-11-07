import QtQuick
import QtQuick.Layouts
import qs.components
import qs.themes

// Control-tab pill tile (docs/ISLAND-R1.md): a round icon, a title and a status line. Tile rule
// (docs/ISLAND.md): the round icon toggles; the body, the chevron or a right-click opens the detail
// section. Without `toggleable` every click opens; without `hasDetail` every click toggles.
StyledRect {
    id: root

    property string icon: ""
    property string label: ""
    property string status: ""
    property bool active: false
    property bool toggleable: true
    property bool hasDetail: true

    signal toggled
    signal opened

    implicitHeight: Appearance.island.control.tile
    radius: height / 2
    color: Colors.surfaceContainerHigh

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.opened();
            else if (root.hasDetail)
                root.opened();
            else if (root.toggleable)
                root.toggled();
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: (Appearance.island.control.tile - Appearance.island.control.tileIcon) / 2
        anchors.rightMargin: Appearance.spacing.normal
        spacing: Appearance.spacing.normal

        StyledRect {
            implicitWidth: Appearance.island.control.tileIcon
            implicitHeight: Appearance.island.control.tileIcon
            radius: height / 2
            color: root.active ? Colors.primary : Colors.surfaceContainerHighest

            Behavior on color {
                CAnim {}
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: root.icon
                fill: root.active ? 1 : 0
                size: Appearance.font.size.large
                color: root.active ? Colors.primaryFg : Colors.surfaceFg
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton && root.toggleable)
                        root.toggled();
                    else
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
                font.pixelSize: Appearance.island.control.title
                font.weight: Font.Medium
            }

            StyledText {
                Layout.fillWidth: true
                text: root.status
                elide: Text.ElideRight
                color: Colors.surfaceVariantFg
                font.pixelSize: Appearance.font.size.small
            }
        }

        MaterialIcon {
            visible: root.hasDetail
            text: "chevron_right"
            color: Colors.surfaceVariantFg
        }
    }
}
