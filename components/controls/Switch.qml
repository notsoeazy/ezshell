import QtQuick
import qs.config
import qs.theme
import qs.components

// HIG switch. Belongs in a list row; elsewhere use a button that toggles.
// Emits `toggled` and leaves changing `checked` to the owner.
Rectangle {
    id: root

    property bool checked
    // The smaller size, for dense rows.
    property bool mini
    property bool disabled
    readonly property real padding: Tokens.spacing.xxs

    signal toggled

    implicitWidth: Math.round(implicitHeight * 1.75)
    implicitHeight: mini ? Tokens.control.xs : Tokens.control.sm
    radius: height / 2
    color: checked ? Theme.accent : Theme.color.fill
    opacity: disabled ? Tokens.state.disabled : 1

    Behavior on color {
        ColorAnim {}
    }

    Rectangle {
        id: thumb

        x: root.checked ? root.width - width - root.padding : root.padding
        y: root.padding
        // Stretches towards the other side while held, as on iOS.
        width: height * (press.down ? 1.25 : 1)
        height: root.height - root.padding * 2
        radius: height / 2
        color: root.checked ? Theme.color.onAccent : Theme.color.thumb

        Behavior on color {
            ColorAnim {}
        }

        Behavior on x {
            Anim {
                style: Tokens.motion.spatialFast
            }
        }

        Behavior on width {
            Anim {
                style: Tokens.motion.effectsFast
            }
        }
    }

    Pressable {
        id: press

        disabled: root.disabled
        radius: root.radius
        onActivated: root.toggled()
    }
}
