import QtQuick
import qs.themes

StyledRect {
    id: root

    property real value: 0
    property color fillColor: Colors.primary

    radius: height / 2
    color: Colors.surfaceContainerHighest

    StyledRect {
        width: root.width * Math.max(0, Math.min(1, root.value))
        height: parent.height
        radius: root.radius
        color: root.fillColor

        Behavior on width {
            Anim {}
        }
    }
}
