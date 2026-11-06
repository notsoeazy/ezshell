import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.themes

// Previous, play/pause, next for the active player (frames 04 and 14).
RowLayout {
    id: root

    property int iconSize: Appearance.font.size.icon
    property color tint: Colors.surfaceFg

    spacing: Appearance.island.expanded.gap

    MaterialIcon {
        text: "skip_previous"
        size: root.iconSize
        color: root.tint
        opacity: Players.active?.canGoPrevious ? 1 : Appearance.control.disabledOpacity

        TapHandler {
            margin: Appearance.spacing.small
            onTapped: Players.previous()
        }
    }

    StyledRect {
        implicitWidth: Appearance.island.dashboard.playButton
        implicitHeight: Appearance.island.dashboard.playButton
        radius: height / 2
        color: Colors.primary

        MaterialIcon {
            anchors.centerIn: parent
            text: Players.playing ? "pause" : "play_arrow"
            fill: 1
            size: root.iconSize
            color: Colors.primaryFg
        }

        TapHandler {
            onTapped: Players.playPause()
        }
    }

    MaterialIcon {
        text: "skip_next"
        size: root.iconSize
        color: root.tint
        opacity: Players.active?.canGoNext ? 1 : Appearance.control.disabledOpacity

        TapHandler {
            margin: Appearance.spacing.small
            onTapped: Players.next()
        }
    }
}
