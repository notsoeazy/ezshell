import QtQuick
import qs.config
import qs.theme
import qs.components

// The red dot that breathes while a recording runs.
Rectangle {
    implicitWidth: Tokens.spacing.sm
    implicitHeight: Tokens.spacing.sm
    radius: height / 2
    color: Theme.color.red

    SequentialAnimation on opacity {
        running: true
        loops: Animation.Infinite

        Anim {
            to: Tokens.state.disabled
            style: Tokens.motion.linear
        }

        Anim {
            to: 1
            style: Tokens.motion.linear
        }
    }
}
