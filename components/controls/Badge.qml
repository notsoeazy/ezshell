import QtQuick
import qs.config
import qs.theme
import qs.components

// A count pill, as tall as an icon of the same size. Pops in when the count
// becomes positive and out at zero.
Rectangle {
    id: root

    property int count
    // Counts above this show as "max+".
    property int max: 99
    property color tint: Theme.accent
    readonly property bool shown: count > 0
    // Keeps the last positive count on screen while the badge fades out.
    property int shownCount: count

    // Whole pixels, so the ends are a clean half circle.
    implicitWidth: Math.ceil(Math.max(implicitHeight, label.implicitWidth + Tokens.spacing.xs * 2))
    implicitHeight: Tokens.icon.sm
    radius: height / 2
    color: tint
    scale: shown ? 1 : 0
    opacity: shown ? 1 : 0

    onCountChanged: {
        if (count > 0)
            shownCount = count;
    }

    Behavior on scale {
        Anim {
            style: Tokens.motion.spatialFast
        }
    }

    Behavior on opacity {
        Anim {
            style: Tokens.motion.effectsFast
        }
    }

    Label {
        id: label

        anchors.centerIn: parent
        text: root.shownCount > root.max ? `${root.max}+` : root.shownCount
        fontSize: Tokens.fontSize.xs
        emphasized: true
        tabular: true
        color: Theme.color.onAccent
    }
}
