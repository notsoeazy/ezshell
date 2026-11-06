import QtQuick
import QtQuick.Layouts
import qs.themes

// Pill button with an optional icon. `filled` and `checked` (for segmented choices) use primary.
StyledRect {
    id: root

    property string text: ""
    property string icon: ""
    property bool filled: false
    property bool checked: false
    readonly property bool emphasized: root.filled || root.checked
    readonly property color foreground: root.emphasized ? Colors.primaryFg : Colors.surfaceFg
    readonly property color idle: mouse.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh

    signal clicked

    implicitWidth: row.implicitWidth + 2 * Appearance.spacing.large
    implicitHeight: Appearance.control.height
    radius: height / 2
    color: root.emphasized ? Colors.primary : root.idle
    opacity: root.enabled ? 1 : Appearance.control.disabledOpacity

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        MaterialIcon {
            visible: root.icon !== ""
            text: root.icon
            size: Appearance.font.size.large
            color: root.foreground
        }

        StyledText {
            visible: root.text !== ""
            text: root.text
            color: root.foreground
            font.weight: Font.Medium
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
