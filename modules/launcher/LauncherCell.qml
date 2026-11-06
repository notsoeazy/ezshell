import QtQuick
import qs.components
import qs.themes

// One grid cell: the item's glyph, large and centered. Long glyphs (kaomoji) shrink to fit the cell.
StyledRect {
    id: root

    required property var modelData
    required property int index
    property bool current: false

    signal hovered
    signal clicked(int modifiers)

    radius: Appearance.rounding.small
    color: root.current ? Colors.surfaceContainerHigh : Colors.transparent

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered()
        onClicked: mouse => root.clicked(mouse.modifiers)
    }

    Text {
        anchors.fill: parent
        anchors.margins: Appearance.spacing.small
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: root.modelData.glyph ?? ""
        color: Colors.surfaceFg
        // Fit shrinks text that doesn't fit, from this size down to the minimum; past that it's cut short.
        fontSizeMode: Text.Fit
        elide: Text.ElideRight
        minimumPixelSize: Appearance.font.size.small
        font.pixelSize: Appearance.island.launcher.glyph
        font.family: root.modelData.font ?? Appearance.font.family
    }
}
