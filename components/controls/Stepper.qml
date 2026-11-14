import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.components.controls

// HIG stepper: a number with minus and plus buttons. Shows the `value` it is
// given and emits `moved`; the owner applies it.
//
//   value, from, to, step   the number and its limits
//   text      what to show for the value, if not the bare number ("3 s")
//   size      one of Tokens.size
RowLayout {
    id: root

    property real value
    property real from: 0
    property real to: 100
    property real step: 1
    property string text: `${value}`
    property Tokens.ControlSize size: Tokens.size.md
    property bool disabled

    signal moved(value: real)

    // Steps are added in whole units of `step`, so 0.1 + 0.2 stays 0.3.
    function nudge(steps: int): void {
        const next = Math.round((value + steps * step) / step) * step;
        moved(Math.max(from, Math.min(to, Number(next.toFixed(6)))));
    }

    spacing: Tokens.spacing.xs

    IconButton {
        icon: "remove"
        size: root.size
        disabled: root.disabled || root.value <= root.from
        onActivated: root.nudge(-1)
    }

    Label {
        Layout.minimumWidth: Tokens.spacing.xxxl * 2
        text: root.text
        horizontalAlignment: Text.AlignHCenter
        tabular: true
        opacity: root.disabled ? Tokens.state.disabled : 1
    }

    IconButton {
        icon: "add"
        size: root.size
        disabled: root.disabled || root.value >= root.to
        onActivated: root.nudge(1)
    }
}
