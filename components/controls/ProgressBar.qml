import QtQuick
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.components

// HIG progress bar. Determinate by default; `indeterminate` slides a segment
// back and forth for work of unknown length.
ClippingRectangle {
    id: root

    // 0..1
    property real value
    property bool indeterminate
    // Position of the sliding segment, 0..1.
    property real slide

    implicitWidth: Tokens.spacing.xxxl * 5
    implicitHeight: Tokens.control.track
    radius: height / 2
    color: Theme.color.fill

    Rectangle {
        x: root.indeterminate ? root.slide * (root.width - width) : 0
        width: root.indeterminate ? root.width * 0.3 : root.width * Math.max(0, Math.min(1, root.value))
        height: parent.height
        radius: height / 2
        color: Theme.accent

        Behavior on width {
            Anim {}
        }
    }

    SequentialAnimation {
        running: root.indeterminate && root.visible
        loops: Animation.Infinite

        Anim {
            target: root
            property: "slide"
            from: 0
            to: 1
            style: Tokens.motion.linear
        }

        Anim {
            target: root
            property: "slide"
            from: 1
            to: 0
            style: Tokens.motion.linear
        }
    }
}
