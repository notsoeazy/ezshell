pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.themes

// Bars bounce only while playing and visible; when paused they sit still at mid height.
Row {
    id: root

    property bool playing: false
    property color tint: Colors.primary
    readonly property list<int> durations: Appearance.island.equalizer.durations

    spacing: Appearance.island.equalizer.gap

    Repeater {
        model: Appearance.island.equalizer.bars

        StyledRect {
            id: bar

            required property int index
            property real level: 0.5
            readonly property real range: Appearance.island.equalizer.maxHeight - Appearance.island.equalizer.minHeight

            anchors.verticalCenter: parent.verticalCenter
            width: Appearance.island.equalizer.barWidth
            height: Appearance.island.equalizer.minHeight + bar.range * (root.playing ? bar.level : 0.5)
            radius: width / 2
            color: root.tint

            SequentialAnimation on level {
                // Never with speed 0: an infinite loop of zero-length steps would spin.
                running: root.playing && root.visible && Appearance.anim.speed > 0
                loops: Animation.Infinite

                Anim {
                    to: 1
                    duration: Appearance.anim.scaled(root.durations[bar.index % root.durations.length])
                }

                Anim {
                    to: 0
                    duration: Appearance.anim.scaled(root.durations[bar.index % root.durations.length])
                }
            }
        }
    }
}
