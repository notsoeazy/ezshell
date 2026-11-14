pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.theme
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.settings

SettingsPage {
    Group {
        Layout.fillWidth: true
        title: "Output"

        LevelRow {
            Layout.fillWidth: true
            title: "Volume"
            icon: Audio.muted ? "volume_off" : Symbols.level("speaker", Audio.volume)
            value: Audio.volume
            onMoved: value => Audio.setVolume(value)

            ToggleButton {
                icon: "volume_off"
                checked: Audio.muted
                onActivated: Audio.toggleMute()
            }
        }

        Repeater {
            model: Audio.sinks

            DeviceRow {
                icon: "speaker"
                current: modelData === Audio.sink
                last: index === Audio.sinks.length - 1
                onActivated: Audio.setSink(modelData)
            }
        }
    }

    Group {
        Layout.fillWidth: true
        title: "Input"

        LevelRow {
            Layout.fillWidth: true
            title: "Volume"
            icon: Audio.micMuted ? "mic_off" : "mic"
            value: Audio.micVolume
            onMoved: value => Audio.setMicVolume(value)

            ToggleButton {
                icon: "mic_off"
                checked: Audio.micMuted
                onActivated: Audio.toggleMicMute()
            }
        }

        Repeater {
            model: Audio.sources

            DeviceRow {
                icon: "mic"
                current: modelData === Audio.source
                last: index === Audio.sources.length - 1
                onActivated: Audio.setSource(modelData)
            }
        }
    }

    Group {
        Layout.fillWidth: true
        title: "Applications"

        Repeater {
            model: Audio.streams

            LevelRow {
                id: stream

                required property PwNode modelData
                required property int index

                Layout.fillWidth: true
                title: Audio.streamLabel(modelData)
                subtitle: Audio.streamDetail(modelData)
                icon: "graphic_eq"
                separator: index < Audio.streams.length - 1
                value: modelData.audio?.volume ?? 0
                onMoved: value => Audio.setNodeVolume(modelData, value)

                ToggleButton {
                    icon: "volume_off"
                    checked: stream.modelData.audio?.muted ?? false
                    onActivated: Audio.toggleNodeMute(stream.modelData)
                }
            }
        }

        ListRow {
            Layout.fillWidth: true
            visible: Audio.streams.length === 0
            title: "Nothing is playing"
            interactive: false
            separator: false
            disabled: true
        }
    }

    // A device to send sound to or take it from; the one in use is ticked.
    component DeviceRow: ListRow {
        id: device

        required property PwNode modelData
        required property int index
        property bool current
        property bool last

        Layout.fillWidth: true
        title: Audio.label(modelData)
        separator: !last

        Icon {
            visible: device.current
            name: "check"
            color: Theme.accent
        }
    }
}
