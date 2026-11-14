import QtQuick
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.components

// A thick bar that fills from the left, with no thumb: for how far through
// something you are. Drag it to move (when `interactive`); it grows a little
// while held. With no progress it is just the empty bar.
//
//   value, from, to, step   the position; `moved(value)` asks for a change
//   shownValue              what the bar shows right now
//   interactive             false makes it a display only
//
// While it is held the bar follows the pointer exactly, and `moved` is sent
// once, on release: what it moves (a track's position) is slow to answer, and
// would drag the bar behind the pointer. After the release the bar stays where
// it was let go until `value` arrives there, so it does not slide back. The
// wheel and the arrow keys send `moved` straight away.
Item {
    id: root

    property real value
    property real from: 0
    property real to: 1
    property real step: 0.05
    property bool interactive: true
    property color tint: Theme.accent
    property bool disabled

    // Where the pointer last put the bar, while held and just after.
    property real dragValue
    property bool settling
    readonly property real shownValue: area.pressed || settling ? dragValue : value

    signal moved(value: real)

    // Let go: stop holding the bar once `value` has caught up, or after a moment.
    Timer {
        id: settle

        interval: Tokens.motion.settle
        onTriggered: root.settling = false
    }

    onValueChanged: {
        if (settling && Math.abs(value - dragValue) <= (to - from) * 0.01)
            settling = false;
    }

    // Tall enough to grab, however thin the bar.
    implicitWidth: Tokens.spacing.xxxl * 5
    implicitHeight: Tokens.control.thumb
    opacity: disabled ? Tokens.state.disabled : 1

    ClippingRectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: area.pressed ? Tokens.control.barActive : Tokens.control.bar
        radius: height / 2
        color: Theme.color.fill

        Behavior on height {
            Anim {
                style: Tokens.motion.effectsFast
            }
        }

        Rectangle {
            // Exactly while held or settling, eased for key, wheel and outside
            // changes.
            width: (root.to > root.from ? Math.max(0, Math.min(1, (root.shownValue - root.from) / (root.to - root.from))) : 0) * parent.width
            height: parent.height
            color: root.tint

            Behavior on width {
                enabled: !area.pressed && !root.settling

                Anim {
                    style: Tokens.motion.effectsFast
                }
            }
        }
    }

    ValueArea {
        id: area

        value: root.value
        from: root.from
        to: root.to
        step: root.step
        disabled: root.disabled || !root.interactive
        onMoved: value => {
            if (pressed) {
                root.dragValue = value;
            } else {
                root.moved(value);
            }
        }
        onPressed: {
            root.settling = false;
            settle.stop();
        }
        onReleased: {
            root.settling = true;
            settle.restart();
            root.moved(root.dragValue);
        }
    }
}
