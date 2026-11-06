import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.themes
import qs.utils

// Volume or brightness level (docs/FIGMA.md, Phase 3 spec). The pill behind it is Surface.qml.
RowLayout {
    id: root

    required property string kind
    readonly property bool isVolume: root.kind === "volume"
    readonly property real level: root.isVolume ? Audio.volume : Brightness.level

    spacing: Appearance.island.osd.gap

    MaterialIcon {
        Layout.leftMargin: Appearance.island.osd.padding
        text: root.isVolume ? Icons.volume(Audio.volume, Audio.muted) : Icons.brightness(Brightness.level)
        size: Appearance.island.osd.icon
    }

    LevelBar {
        Layout.fillWidth: true
        implicitHeight: Appearance.island.osd.trackHeight
        value: root.level
    }

    StyledText {
        Layout.preferredWidth: Appearance.island.osd.valueWidth
        Layout.rightMargin: Appearance.island.osd.padding
        horizontalAlignment: Text.AlignRight
        text: `${Math.round(root.level * 100)}`
        color: Colors.surfaceVariantFg
        font.weight: Font.Medium
    }
}
