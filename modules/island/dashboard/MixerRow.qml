import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.components
import qs.services
import qs.themes

// One mixer line on the Media tab: a device or an app stream with a mute button, its name, its level and
// a volume slider. Devices also show whether they're the default; clicking the name of another makes it
// the default (`chosen`).
ColumnLayout {
    id: root

    required property PwNode node
    property string kindIcon: "volume_up"
    property string mutedIcon: "volume_off"
    property bool device: false
    property bool isDefault: false
    readonly property real volume: root.node?.audio?.volume ?? 0
    readonly property bool muted: root.node?.audio?.muted ?? false

    signal chosen

    Layout.fillWidth: true
    spacing: 0

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        MaterialIcon {
            text: root.muted ? root.mutedIcon : root.kindIcon
            color: root.muted ? Colors.surfaceVariantFg : Colors.primary

            TapHandler {
                margin: Appearance.spacing.small
                onTapped: Audio.toggleMuteOf(root.node.id)
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: Audio.label(root.node)
            elide: Text.ElideRight
            font.weight: root.isDefault ? Font.DemiBold : Font.Normal

            TapHandler {
                enabled: root.device && !root.isDefault
                cursorShape: Qt.PointingHandCursor
                onTapped: root.chosen()
            }
        }

        MaterialIcon {
            visible: root.device
            text: root.isDefault ? "radio_button_checked" : "radio_button_unchecked"
            color: root.isDefault ? Colors.primary : Colors.surfaceVariantFg

            TapHandler {
                margin: Appearance.spacing.small
                enabled: !root.isDefault
                onTapped: root.chosen()
            }
        }

        StyledText {
            Layout.preferredWidth: Appearance.island.dashboard.mixerPercent
            horizontalAlignment: Text.AlignRight
            text: root.muted ? "Muted" : `${Math.round(root.volume * 100)}%`
            color: Colors.surfaceVariantFg
            font.pixelSize: Appearance.font.size.small
        }
    }

    StyledSlider {
        Layout.fillWidth: true
        value: root.muted ? 0 : root.volume
        onMoved: value => Audio.setVolumeOf(root.node.id, value)
    }
}
