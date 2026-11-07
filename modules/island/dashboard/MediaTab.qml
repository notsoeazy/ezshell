pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.components
import qs.modules.island.dashboard.cards
import qs.services
import qs.themes

// Media tab: the player on top while something plays, then a pavucontrol-style mixer. Devices on the
// left (pick the default, volume, mute), apps on the right (playback and recording streams).
Flickable {
    id: root

    function time(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    implicitHeight: Math.min(column.implicitHeight, Appearance.island.expanded.pageMaxHeight)
    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    // A card listing app streams, or a quiet line when there are none.
    component Streams: Card {
        id: streams

        property list<PwNode> nodes: []
        property string kindIcon: ""
        property string mutedIcon: ""
        property string empty: ""

        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop

        StyledText {
            visible: streams.nodes.length === 0
            text: streams.empty
            color: Colors.surfaceVariantFg
        }

        Repeater {
            model: streams.nodes

            MixerRow {
                required property PwNode modelData

                node: modelData
                kindIcon: streams.kindIcon
                mutedIcon: streams.mutedIcon
            }
        }
    }

    ColumnLayout {
        id: column

        width: root.width
        spacing: Appearance.island.control.gap

        Card {
            Layout.fillWidth: true
            visible: Players.active !== null

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.island.expanded.gap

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
                        sourceSize.width: Appearance.island.dashboard.mediaArt
                        sourceSize.height: Appearance.island.dashboard.mediaArt
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        Layout.fillWidth: true
                        text: Players.title
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.font.size.large
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
                }

                MediaControls {}
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

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.island.control.gap

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: Appearance.island.control.gap

                Card {
                    Layout.fillWidth: true
                    icon: "speaker"
                    title: "Output"

                    Repeater {
                        model: Audio.outputs

                        MixerRow {
                            required property PwNode modelData

                            node: modelData
                            device: true
                            isDefault: modelData === Audio.sink
                            onChosen: Audio.setOutput(modelData.name)
                        }
                    }
                }

                Card {
                    Layout.fillWidth: true
                    icon: "mic"
                    title: "Input"

                    Repeater {
                        model: Audio.inputs

                        MixerRow {
                            required property PwNode modelData

                            node: modelData
                            device: true
                            kindIcon: "mic"
                            mutedIcon: "mic_off"
                            isDefault: modelData === Audio.source
                            onChosen: Audio.setInput(modelData.name)
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: Appearance.island.control.gap

                Streams {
                    icon: "apps"
                    title: "Playback"
                    nodes: Audio.streams
                    kindIcon: "volume_up"
                    mutedIcon: "volume_off"
                    empty: "No apps playing"
                }

                Streams {
                    icon: "graphic_eq"
                    title: "Recording"
                    nodes: Audio.recordings
                    kindIcon: "mic"
                    mutedIcon: "mic_off"
                    empty: "No apps recording"
                }
            }
        }
    }
}
