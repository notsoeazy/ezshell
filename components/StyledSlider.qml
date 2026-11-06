import QtQuick
import qs.themes

// Horizontal 0-1 slider: drag, click or scroll. Reports `moved`; the owner writes the value back.
Item {
    id: root

    property real value: 0
    // Change per wheel notch.
    property real step: 0.05

    signal moved(real value)

    function valueAt(x: real): real {
        return Math.max(0, Math.min(1, x / root.width));
    }

    implicitWidth: Appearance.control.sliderWidth
    implicitHeight: Appearance.control.height
    opacity: root.enabled ? 1 : Appearance.control.disabledOpacity

    LevelBar {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: Appearance.control.trackHeight
        value: root.value
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.moved(root.valueAt(mouse.x))
        onPositionChanged: mouse => root.moved(root.valueAt(mouse.x))
    }

    WheelArea {
        anchors.fill: parent
        onStepped: step => root.moved(Math.max(0, Math.min(1, root.value - step * root.step)))
    }
}
