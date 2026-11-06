import QtQuick
import qs.themes

Text {
    color: Colors.surfaceFg
    font.family: Appearance.font.family
    font.pixelSize: Appearance.font.size.normal

    Behavior on color {
        CAnim {}
    }
}
