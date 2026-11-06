import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components
import qs.modules.island.dashboard.cards
import qs.services
import qs.themes

// Overview media card (frame 14), on primaryContainer: art, title, artist · player, progress, controls.
Card {
    id: root

    readonly property real progress: Players.length > 0 ? Players.position / Players.length : 0

    color: Colors.primaryContainer

    StyledText {
        visible: !Players.active
        text: "Nothing playing"
        color: Colors.primaryContainerFg
    }

    RowLayout {
        visible: Players.active !== null
        spacing: Appearance.island.expanded.gap

        ClippingRectangle {
            implicitWidth: Appearance.island.dashboard.cardArt
            implicitHeight: Appearance.island.dashboard.cardArt
            radius: Appearance.island.dashboard.artRadius
            color: Colors.surfaceContainerHighest

            Image {
                anchors.fill: parent
                source: Players.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: Players.title
                elide: Text.ElideRight
                color: Colors.primaryContainerFg
                font.weight: Font.DemiBold
            }

            StyledText {
                Layout.fillWidth: true
                text: [Players.artist, Players.identity].filter(s => s !== "").join(" · ")
                elide: Text.ElideRight
                color: Colors.primaryContainerFg
                opacity: Appearance.island.expanded.secondaryOpacity
                font.pixelSize: Appearance.font.size.small
            }

            LevelBar {
                Layout.fillWidth: true
                implicitHeight: Appearance.control.trackHeight
                value: root.progress
                color: Qt.alpha(Colors.primaryContainerFg, Appearance.island.outlineOpacity)
                fillColor: Colors.primaryContainerFg
            }

            MediaControls {
                tint: Colors.primaryContainerFg
            }
        }
    }
}
