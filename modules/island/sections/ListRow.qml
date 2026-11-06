import QtQuick
import QtQuick.Layouts
import qs.components
import qs.themes

// List row in the style of frame 08: icon box, title and subtitle, then trailing controls (children).
StyledRect {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    default property alias trailing: trail.data

    signal activated

    Layout.fillWidth: true
    implicitHeight: Appearance.island.expanded.row
    radius: Appearance.rounding.normal
    color: mouse.containsMouse ? Colors.surfaceContainerHigh : Colors.transparent

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.spacing.normal
        anchors.rightMargin: Appearance.spacing.normal
        spacing: Appearance.island.expanded.gap

        StyledRect {
            implicitWidth: Appearance.island.expanded.iconBox
            implicitHeight: Appearance.island.expanded.iconBox
            radius: Appearance.island.expanded.iconBoxRadius
            color: root.active ? Colors.primaryContainer : Colors.surfaceContainerHighest

            MaterialIcon {
                anchors.centerIn: parent
                text: root.icon
                fill: root.active ? 1 : 0
                color: root.active ? Colors.primaryContainerFg : Colors.surfaceFg
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideRight
                font.weight: Font.Medium
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.subtitle
                elide: Text.ElideRight
                color: Colors.surfaceVariantFg
                font.pixelSize: Appearance.font.size.small
            }
        }

        RowLayout {
            id: trail

            spacing: Appearance.spacing.normal
        }
    }
}
