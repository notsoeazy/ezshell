pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.theme
import qs.components
import qs.services

// One screen of the chooser. Point at a window to take it, drag to take an
// area, press Return for the whole screen, Escape to give up. For a
// screenshot the screen is shown frozen; for a recording it is live.
MouseArea {
    id: root

    required property ShellScreen screen
    readonly property bool frozen: Capture.picking === "screenshot"
    readonly property list<var> windows: Hypr.windowsOn(screen)

    // Where the drag began, and whether one is under way.
    property point origin
    property bool dragging
    // What would be taken now: a dragged area, else the window under the
    // pointer, else the whole screen.
    property rect area: Qt.rect(0, 0, width, height)

    function windowAt(x: real, y: real): rect {
        for (const w of windows) {
            if (x >= w.x && y >= w.y && x < w.x + w.width && y < w.y + w.height)
                return clip(w);
        }
        return Qt.rect(0, 0, width, height);
    }

    // The part of a rectangle that is on this screen.
    function clip(r: rect): rect {
        const left = Math.max(0, r.x);
        const top = Math.max(0, r.y);
        return Qt.rect(left, top, Math.min(width, r.x + r.width) - left, Math.min(height, r.y + r.height) - top);
    }

    function take(): void {
        Capture.picked(screen, area, Hypr.monitorScale(screen));
    }

    hoverEnabled: true
    cursorShape: Qt.CrossCursor
    focus: true

    Keys.onEscapePressed: Capture.cancel()
    Keys.onReturnPressed: {
        area = Qt.rect(0, 0, width, height);
        take();
    }
    Keys.onEnterPressed: {
        area = Qt.rect(0, 0, width, height);
        take();
    }

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onPressed: event => {
        // The right button gives up.
        if (event.button === Qt.RightButton)
            Capture.cancel();
        else
            origin = Qt.point(event.x, event.y);
    }
    onPositionChanged: event => {
        if (pressed) {
            // A small movement while clicking is still a click.
            if (!dragging && Math.abs(event.x - origin.x) + Math.abs(event.y - origin.y) > Tokens.spacing.sm)
                dragging = true;
            if (dragging)
                area = clip(Qt.rect(Math.min(origin.x, event.x), Math.min(origin.y, event.y), Math.abs(event.x - origin.x), Math.abs(event.y - origin.y)));
        } else {
            area = windowAt(event.x, event.y);
        }
    }
    onReleased: event => {
        if (event.button === Qt.LeftButton)
            take();
    }

    Image {
        anchors.fill: parent
        visible: root.frozen
        source: root.frozen ? `file://${Capture.still(root.screen.name)}?${Capture.stamp}` : ""
        cache: false
        asynchronous: false
    }

    // Everything outside the area is dimmed: four pieces around it.
    Rectangle {
        width: parent.width
        height: frame.y
        color: Theme.color.scrim
    }

    Rectangle {
        y: frame.y + frame.height
        width: parent.width
        height: parent.height - y
        color: Theme.color.scrim
    }

    Rectangle {
        y: frame.y
        width: frame.x
        height: frame.height
        color: Theme.color.scrim
    }

    Rectangle {
        x: frame.x + frame.width
        y: frame.y
        width: parent.width - x
        height: frame.height
        color: Theme.color.scrim
    }

    Rectangle {
        id: frame

        x: root.area.x
        y: root.area.y
        width: root.area.width
        height: root.area.height
        color: "transparent"
        border.width: Tokens.state.focusRing
        border.color: Theme.accent

        // Glides between windows; follows a drag exactly.
        Behavior on x {
            enabled: !root.dragging

            Anim {
                style: Tokens.motion.effectsFast
            }
        }

        Behavior on y {
            enabled: !root.dragging

            Anim {
                style: Tokens.motion.effectsFast
            }
        }

        Behavior on width {
            enabled: !root.dragging

            Anim {
                style: Tokens.motion.effectsFast
            }
        }

        Behavior on height {
            enabled: !root.dragging

            Anim {
                style: Tokens.motion.effectsFast
            }
        }

        // The area's size, while dragging.
        Surface {
            anchors.left: parent.left
            anchors.bottom: parent.top
            anchors.bottomMargin: Tokens.spacing.xs
            visible: root.dragging
            implicitWidth: size.implicitWidth + Tokens.spacing.sm * 2
            implicitHeight: size.implicitHeight + Tokens.spacing.xxs * 2
            radius: Tokens.radius.sm

            Label {
                id: size

                anchors.centerIn: parent
                text: `${Math.round(root.area.width)} × ${Math.round(root.area.height)}`
                fontSize: Tokens.fontSize.sm
                tabular: true
            }
        }
    }

    Surface {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.spacing.xxxl
        implicitWidth: hint.implicitWidth + Tokens.spacing.lg * 2
        implicitHeight: Tokens.control.xl
        radius: height / 2
        opacity: root.dragging ? 0 : 1

        Behavior on opacity {
            Anim {
                style: Tokens.motion.effectsFast
            }
        }

        Label {
            id: hint

            anchors.centerIn: parent
            text: `${root.frozen ? "Screenshot" : "Record"}: click a window, drag an area, Return for the whole screen, Esc to cancel`
            fontSize: Tokens.fontSize.md
        }
    }
}
