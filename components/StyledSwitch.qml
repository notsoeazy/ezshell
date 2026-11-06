import QtQuick
import qs.themes

// On/off switch. It doesn't change itself: the owner writes the new state and binds `checked` back.
StyledRect {
    id: root

    property bool checked: false

    signal toggled(bool checked)

    implicitWidth: Appearance.control.switchWidth
    implicitHeight: Appearance.control.switchHeight
    radius: height / 2
    color: root.checked ? Colors.primary : Colors.surfaceContainerHighest
    opacity: root.enabled ? 1 : Appearance.control.disabledOpacity

    StyledRect {
        width: root.height - 2 * Appearance.control.knobInset
        height: width
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - Appearance.control.knobInset : Appearance.control.knobInset
        color: root.checked ? Colors.primaryFg : Colors.outline

        Behavior on x {
            Anim {}
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
