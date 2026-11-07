import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components
import qs.services
import qs.themes

// Now playing on a track change: the island widens to art, title and artist, with the equalizer on the
// right where it sits at rest. The pill fits this row (Surface.musicWidth), so it stays centered.
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
            sourceSize.width: Appearance.island.music.art
            sourceSize.height: Appearance.island.music.art
        }

        MaterialIcon {
            anchors.centerIn: parent
            visible: Players.artUrl === ""
            text: "music_note"
            color: root.tint
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.maximumWidth: Appearance.island.music.textMaxWidth
        spacing: 0

        StyledText {
            Layout.fillWidth: true
            text: Players.title
            elide: Text.ElideRight
            font.weight: Font.DemiBold
        }

        StyledText {
            Layout.fillWidth: true
            visible: text !== ""
            text: Players.artist
            elide: Text.ElideRight
            color: Colors.surfaceVariantFg
            font.pixelSize: Appearance.font.size.small
        }
    }

    Equalizer {
        playing: Players.playing
        tint: root.tint
    }
}
