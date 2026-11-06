pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.components
import qs.services
import qs.themes
import qs.utils

// Audio: output and input volume with mute, and the default device for each.
ColumnLayout {
    id: root

    spacing: Appearance.island.expanded.gap

    component Heading: StyledText {
        color: Colors.surfaceVariantFg
        font.pixelSize: Appearance.font.size.small
        font.weight: Font.Medium
    }

    component VolumeRow: RowLayout {
        id: volumeRow

        required property string icon
        required property real level
        required property bool muted

        signal moved(real level)
        signal muteToggled

        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledButton {
            icon: volumeRow.icon
            checked: volumeRow.muted
            onClicked: volumeRow.muteToggled()
        }

        StyledSlider {
            Layout.fillWidth: true
            value: volumeRow.level
            onMoved: level => volumeRow.moved(level)
        }

        StyledText {
            Layout.preferredWidth: Appearance.island.osd.valueWidth
            horizontalAlignment: Text.AlignRight
            text: `${Math.round(volumeRow.level * 100)}`
            color: Colors.surfaceVariantFg
        }
    }

    component DeviceRow: ListRow {
        id: deviceRow

        required property PwNode modelData
        required property PwNode current
        property string kindIcon: ""

        signal chosen(string name)

        icon: deviceRow.kindIcon
        title: Audio.label(deviceRow.modelData)
        active: deviceRow.modelData === deviceRow.current
        subtitle: deviceRow.active ? "Default" : ""
        onActivated: deviceRow.chosen(deviceRow.modelData.name)
    }

    // Who is using the mic or camera; the island's privacy indicator opens this section.
    component InUse: RowLayout {
        id: inUse

        required property string icon
        required property string text

        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        MaterialIcon {
            text: inUse.icon
            fill: 1
            color: Colors.warning
        }

        StyledText {
            Layout.fillWidth: true
            text: inUse.text
            elide: Text.ElideRight
            color: Colors.warning
        }
    }

    InUse {
        visible: Audio.micInUse
        icon: "mic"
        text: `Microphone in use by ${Audio.micApps.join(", ")}`
    }

    InUse {
        visible: Camera.inUse
        icon: "videocam"
        text: `Camera in use by ${Camera.apps.join(", ")}`
    }

    Heading {
        text: "Output"
    }

    VolumeRow {
        icon: Icons.volume(Audio.volume, Audio.muted)
        level: Audio.volume
        muted: Audio.muted
        onMoved: level => Audio.set(level)
        onMuteToggled: Audio.toggleMute()
    }

    Repeater {
        model: Audio.outputs

        DeviceRow {
            current: Audio.sink
            kindIcon: "speaker"
            onChosen: name => Audio.setOutput(name)
        }
    }

    Heading {
        text: "Input"
    }

    VolumeRow {
        icon: Audio.micMuted ? "mic_off" : "mic"
        level: Audio.micVolume
        muted: Audio.micMuted
        onMoved: level => Audio.setMicVolume(level)
        onMuteToggled: Audio.toggleMicMute()
    }

    Repeater {
        model: Audio.inputs

        DeviceRow {
            current: Audio.source
            kindIcon: "mic"
            onChosen: name => Audio.setInput(name)
        }
    }

    SettingsLink {
        label: "Sound settings"
        page: "audio"
    }
}
