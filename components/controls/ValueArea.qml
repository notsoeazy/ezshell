import QtQuick

// Shared input for sliders: maps drag, wheel and arrow keys to a value and
// emits `moved`. The owner applies the value; this never changes it itself.
MouseArea {
    id: root

    property real value
    property real from: 0
    property real to: 1
    // Wheel and arrow-key step, as a fraction of the range.
    property real step: 0.05
    property bool disabled
    property bool wheelAdjusts: true
    // Width at each end that does not map to a value (half a thumb).
    property real inset
    // The value as 0..1 along the track.
    readonly property real fraction: to > from ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0

    signal moved(value: real)

    function moveTo(x: real): void {
        const usable = width - inset * 2;
        const pos = usable > 0 ? Math.max(0, Math.min(1, (x - inset) / usable)) : 0;
        moved(from + pos * (to - from));
    }

    function nudge(steps: int): void {
        moved(Math.max(from, Math.min(to, value + steps * step * (to - from))));
    }

    anchors.fill: parent
    enabled: !disabled
    hoverEnabled: true
    preventStealing: true
    activeFocusOnTab: !disabled

    onPressed: event => moveTo(event.x)
    onPositionChanged: event => {
        if (pressed)
            moveTo(event.x);
    }
    onWheel: event => {
        if (wheelAdjusts)
            nudge(event.angleDelta.y > 0 ? 1 : -1);
        else
            event.accepted = false;
    }
    Keys.onLeftPressed: nudge(-1)
    Keys.onRightPressed: nudge(1)
}
