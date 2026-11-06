pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components
import qs.modules.island.dashboard.cards
import qs.services
import qs.themes

// Media tab (frame 04): art, title and artist, seekable progress, controls, and a player picker.
ColumnLayout {
    id: root

    function time(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    spacing: Appearance.island.expanded.gap

    StyledText {
        visible: !Players.active
        text: "Nothing is playing"
        color: Colors.surfaceVariantFg
    }

    RowLayout {
        visible: Players.active !== null
        spacing: Appearance.settings.padding

        ClippingRectangle {
            implicitWidth: Appearance.island.dashboard.mediaArt
            implicitHeight: Appearance.island.dashboard.mediaArt
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
            spacing: Appearance.spacing.normal

            StyledText {
                Layout.fillWidth: true
                text: Players.title
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.size.title
                font.weight: Font.DemiBold
            }

            StyledText {
                Layout.fillWidth: true
                text: [Players.artist, Players.identity].filter(s => s !== "").join(" · ")
                elide: Text.ElideRight
                color: Colors.surfaceVariantFg
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                StyledText {
                    text: root.time(Players.position)
                    color: Colors.surfaceVariantFg
                    font.pixelSize: Appearance.font.size.small
                }

                StyledSlider {
                    Layout.fillWidth: true
                    enabled: Players.canSeek && Players.length > 0
                    value: Players.length > 0 ? Players.position / Players.length : 0
                    onMoved: level => Players.seek(level * Players.length)
                }

                StyledText {
                    text: root.time(Players.length)
                    color: Colors.surfaceVariantFg
                    font.pixelSize: Appearance.font.size.small
                }
            }

            MediaControls {
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    // Only when there's a choice: one button per player; the picked one becomes the active player.
    RowLayout {
        visible: Players.players.length > 1
        spacing: Appearance.spacing.normal

        Repeater {
            model: Players.players

            StyledButton {
                required property var modelData

                icon: "music_note"
                text: modelData.identity
                checked: modelData === Players.active
                onClicked: Players.select(modelData.identity)
            }
        }
    }
}
