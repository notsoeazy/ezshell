import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components
import qs.services
import qs.state
import qs.themes

// Control tab media row (docs/ISLAND-R1.md): only while a player is active. The art or the text opens the
// Media tab; the buttons only control playback. The taps don't overlap: a row-wide TapHandler behind the
// buttons competed with theirs, and the buttons stopped working.
StyledRect {
    id: root

    required property string screenName

    visible: Players.active !== null
    implicitHeight: Appearance.island.control.art + 2 * Appearance.island.control.cardPadding
    radius: Appearance.island.control.cardRadius
    color: Colors.surfaceContainerHigh

    RowLayout {
        anchors.fill: parent
        anchors.margins: Appearance.island.control.cardPadding
        spacing: Appearance.island.control.gap + Appearance.spacing.small

        ClippingRectangle {
            implicitWidth: Appearance.island.control.art
            implicitHeight: Appearance.island.control.art
            radius: Appearance.island.control.artRadius
            color: Colors.surfaceContainerHighest

            Image {
                anchors.fill: parent
                source: Players.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: Appearance.island.control.art
                sourceSize.height: Appearance.island.control.art
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: Players.artUrl === ""
                text: "music_note"
                color: Colors.surfaceVariantFg
            }

            TapHandler {
                onTapped: Visibility.openByPointer("media", root.screenName)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            TapHandler {
                onTapped: Visibility.openByPointer("media", root.screenName)
            }

            StyledText {
                Layout.fillWidth: true
                text: Players.title !== "" ? Players.title : Players.identity
                elide: Text.ElideRight
                font.weight: Font.DemiBold
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: [Players.artist, Players.identity].filter(t => t !== "").join(" · ")
                elide: Text.ElideRight
                color: Colors.surfaceVariantFg
                font.pixelSize: Appearance.font.size.small
            }
        }

        MaterialIcon {
            text: "skip_previous"
            fill: 1

            TapHandler {
                margin: Appearance.spacing.small
                onTapped: Players.previous()
            }
        }

        MaterialIcon {
            text: Players.playing ? "pause" : "play_arrow"
            fill: 1

            TapHandler {
                margin: Appearance.spacing.small
                onTapped: Players.playPause()
            }
        }

        MaterialIcon {
            text: "skip_next"
            fill: 1

            TapHandler {
                margin: Appearance.spacing.small
                onTapped: Players.next()
            }
        }
    }
}
