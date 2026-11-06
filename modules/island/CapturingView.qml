import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.themes

// A capture under way: picking a region (slurp is up), the recorder starting (a pulsing dot, since
// gpu-screen-recorder takes a second or two), then a short "Recording" before the indicator takes over.
RowLayout {
    id: root

    readonly property string phase: Capture.phase
    readonly property var titles: ({
            selecting: "Drag to select",
            starting: "Starting recording…",
            recording: "Recording"
        })

    spacing: Appearance.spacing.normal

    StyledRect {
        id: dot

        visible: root.phase !== "selecting"
        implicitWidth: Appearance.island.indicatorDot
        implicitHeight: Appearance.island.indicatorDot
        radius: height / 2
        color: Colors.error

        SequentialAnimation on opacity {
            running: root.phase === "starting"
            loops: Animation.Infinite
            alwaysRunToEnd: true

            Anim {
                to: Appearance.island.dimmedOpacity
                duration: Appearance.anim.scaled(Appearance.anim.pulse)
            }

            Anim {
                to: 1
                duration: Appearance.anim.scaled(Appearance.anim.pulse)
            }
        }
    }

    MaterialIcon {
        visible: root.phase === "selecting"
        text: "screenshot_region"
        color: Colors.primary
    }

    StyledText {
        Layout.fillWidth: true
        text: root.titles[root.phase] ?? ""
        font.weight: Font.Medium
    }

    StyledText {
        text: root.phase === "selecting" ? "Esc to cancel" : "click the red indicator to stop"
        visible: root.phase !== "starting"
        color: Colors.surfaceVariantFg
        font.pixelSize: Appearance.font.size.small
    }
}
