import QtQuick
import qs.config
import qs.components

// HIG activity indicator, for work of unknown length. Never morph it into a
// progress bar; pick one for the task.
Item {
    id: root

    property real size: Tokens.icon.md
    property bool running: true

    implicitWidth: size
    implicitHeight: size

    Icon {
        anchors.centerIn: parent
        name: "progress_activity"
        size: root.size
        level: Icon.Secondary

        Anim on rotation {
            running: root.running && root.visible
            loops: Animation.Infinite
            from: 0
            to: 360
            style: Tokens.motion.linear
        }
    }
}
