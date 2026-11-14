import QtQuick
import qs.theme
import qs.components

// A hairline. The owner gives it its length (fill width or fill height).
Rectangle {
    implicitWidth: 1
    implicitHeight: 1
    color: Theme.color.separator

    Behavior on color {
        ColorAnim {}
    }
}
