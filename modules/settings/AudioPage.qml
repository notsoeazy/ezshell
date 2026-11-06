pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.themes

ColumnLayout {
    id: root

    spacing: Appearance.settings.padding

    Section {
        title: "Output"

        Repeater {
            model: Audio.outputs

            SettingRow {
                id: output

                required property var modelData
                readonly property bool current: output.modelData === Audio.sink

                icon: "speaker"
                label: Audio.label(output.modelData)

                StyledButton {
                    text: output.current ? "Default" : "Use"
                    checked: output.current
                    onClicked: Audio.setOutput(output.modelData.name)
                }
            }
        }
    }

    Section {
        title: "Input"

        Repeater {
            model: Audio.inputs

            SettingRow {
                id: input

                required property var modelData
                readonly property bool current: input.modelData === Audio.source

                icon: "mic"
                label: Audio.label(input.modelData)

                StyledButton {
                    text: input.current ? "Default" : "Use"
                    checked: input.current
                    onClicked: Audio.setInput(input.modelData.name)
                }
            }
        }
    }

    Section {
        title: "Apps"
        description: "Volume per app while it plays sound."

        Repeater {
            model: Audio.streams

            SettingRow {
                id: stream

                required property var modelData
                readonly property bool muted: stream.modelData.audio?.muted ?? false

                icon: "apps"
                label: Audio.label(stream.modelData)

                StyledButton {
                    icon: stream.muted ? "volume_off" : "volume_up"
                    checked: stream.muted
                    onClicked: Audio.toggleStreamMute(stream.modelData.id)
                }

                StyledSlider {
                    value: stream.modelData.audio?.volume ?? 0
                    onMoved: volume => Audio.setStreamVolume(stream.modelData.id, volume)
                }
            }
        }

        StyledText {
            visible: Audio.streams.length === 0
            text: "No apps are playing sound"
            color: Colors.surfaceVariantFg
        }
    }
}
