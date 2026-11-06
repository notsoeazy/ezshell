import QtQuick

// Turns mouse-wheel and touchpad scrolling into whole steps: -1 per notch up, +1 per notch down.
MouseArea {
    id: root

    // Touchpads send many small deltas; they add up here until they make a full notch.
    property real accumulated: 0

    signal stepped(int step)

    acceptedButtons: Qt.NoButton
    onWheel: wheel => {
        // 120 is one mouse-wheel notch in Qt's angleDelta units.
        root.accumulated += wheel.angleDelta.y;
        while (Math.abs(root.accumulated) >= 120) {
            const up = root.accumulated > 0;
            root.accumulated -= up ? 120 : -120;
            root.stepped(up ? -1 : 1);
        }
    }
}
