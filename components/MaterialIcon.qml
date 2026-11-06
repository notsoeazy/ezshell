import QtQuick
import qs.themes

StyledText {
    // Rounded to one decimal: each distinct axis value creates a new font instance.
    property real fill: 0
    property int size: Appearance.font.size.icon

    font.family: Appearance.font.icons
    font.pixelSize: size
    font.variableAxes: ({
            "FILL": Math.round(fill * 10) / 10,
            "opsz": size
        })
}
