import QtQuick
import qs.themes

StyledText {
    // Rounded to one decimal: each distinct axis value creates a new font instance.
    property real fill: 0
    property int size: Appearance.font.size.icon

    // Qt's default distance-field glyph cache ignores variable axes, so a filled and an outlined copy of the
    // same icon overwrite each other's glyphs (a filled tile icon showed the outline's ring through it).
    // Native rendering caches glyphs per font instance, axes included.
    renderType: Text.NativeRendering
    font.family: Appearance.font.icons
    font.pixelSize: size
    font.variableAxes: ({
            "FILL": Math.round(fill * 10) / 10,
            "opsz": size
        })
}
