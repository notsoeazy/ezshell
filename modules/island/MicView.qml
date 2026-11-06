import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.themes

// Mic mute feedback. No Figma frame yet, so it uses the OSD's size and spacing.
RowLayout {
    id: root

    spacing: Appearance.island.osd.gap

    MaterialIcon {
        text: Audio.micMuted ? "mic_off" : "mic"
        size: Appearance.island.osd.icon
        color: Audio.micMuted ? Colors.error : Colors.surfaceFg
    }

    StyledText {
        text: Audio.micMuted ? "Microphone muted" : "Microphone on"
        font.weight: Font.Medium
    }
}
