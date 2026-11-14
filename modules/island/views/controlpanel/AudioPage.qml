pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.config
import qs.theme
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils

// Where sound goes and where it comes from. Click a device to make it the
// default.
PanelPage {
    title: "Sound"

    Label {
        text: "Output"
        fontSize: Tokens.fontSize.sm
        level: Label.Secondary
    }

    LevelSlider {
        Layout.fillWidth: true
        icon: Audio.muted ? "volume_off" : Symbols.level("speaker", Audio.volume)
        value: Audio.volume
        tint: Audio.muted ? Theme.color.grey : Theme.accent
        onMoved: value => Audio.setVolume(value)
    }

    Devices {
        nodes: Audio.sinks
        current: Audio.sink
        icon: "speaker"
        onChosen: node => Audio.setSink(node)
    }

    Label {
        text: "Input"
        fontSize: Tokens.fontSize.sm
        level: Label.Secondary
    }

    LevelSlider {
        Layout.fillWidth: true
        icon: Audio.micMuted ? "mic_off" : "mic"
        value: Audio.micVolume
        tint: Audio.micMuted ? Theme.color.grey : Theme.accent
        onMoved: value => Audio.setMicVolume(value)
    }

    Devices {
        nodes: Audio.sources
        current: Audio.source
        icon: "mic"
        onChosen: node => Audio.setSource(node)
    }

    component Devices: List {
        id: devices

        required property list<PwNode> nodes
        required property PwNode current
        required property string icon

        signal chosen(node: PwNode)

        Layout.fillWidth: true
        maxHeight: Tokens.control.row * 4 + Tokens.spacing.xs * 2
        color: Theme.color.fillTertiary
        selectable: false
        model: nodes

        delegate: ListRow {
            id: row

            required property PwNode modelData
            required property int index

            width: ListView.view.width
            title: Audio.label(modelData)
            icon: devices.icon
            separator: index < devices.nodes.length - 1
            onActivated: devices.chosen(modelData)

            Icon {
                visible: row.modelData === devices.current
                name: "check"
                color: Theme.accent
            }
        }
    }
}
