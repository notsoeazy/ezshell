import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components
import qs.services
import qs.themes

// Compact live activity on a track change (docs/design/03-compact-music.png): art, title, equalizer.
RowLayout {
    id: root

    readonly property color tint: Players.hasAccent ? Players.accent : Colors.primary

    spacing: Appearance.spacing.normal

    ClippingRectangle {
        implicitWidth: Appearance.island.music.art
        implicitHeight: Appearance.island.music.art
        radius: Appearance.island.music.artRadius
        color: Colors.surfaceContainerHighest

        Image {
            anchors.fill: parent
            visible: Players.artUrl !== ""
            source: Players.artUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        MaterialIcon {
            anchors.centerIn: parent
            visible: Players.artUrl === ""
            text: "music_note"
            size: Appearance.font.size.large
            color: root.tint
        }
    }

    StyledText {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: Players.title
        elide: Text.ElideRight
        font.weight: Font.Medium
    }

    Equalizer {
        playing: Players.playing
        tint: root.tint
    }
}
