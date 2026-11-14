import QtQuick
import qs.config
import qs.theme
import qs.components

// HIG tooltip: a short phrase that appears after hovering for a moment. Bind
// `shown` to the hover state of what it describes, e.g. a Pressable's
// `hovered`. It draws on top of the whole window, so nothing clips it.
Item {
    id: root

    required property string text
    property bool shown
    // What the tooltip points at.
    property Item target: parent
    property bool active
    readonly property Item overlay: Window.contentItem
    readonly property real gap: Tokens.spacing.xs

    function place(): void {
        if (!target || !overlay)
            return;

        const below = target.mapToItem(overlay, target.width / 2, target.height + gap);
        const fitsBelow = below.y + bubble.height + gap <= overlay.height;
        bubble.x = Math.max(gap, Math.min(overlay.width - bubble.width - gap, below.x - bubble.width / 2));
        bubble.y = fitsBelow ? below.y : target.mapToItem(overlay, 0, -gap).y - bubble.height;
    }

    onShownChanged: {
        if (shown) {
            delay.restart();
        } else {
            delay.stop();
            active = false;
        }
    }

    Timer {
        id: delay

        interval: Tokens.state.tooltipDelay
        onTriggered: {
            root.place();
            root.active = true;
        }
    }

    Surface {
        id: bubble

        parent: root.overlay
        z: 1000
        width: label.implicitWidth + Tokens.spacing.sm * 2
        height: label.implicitHeight + Tokens.spacing.xs * 2
        radius: Tokens.radius.sm
        border.width: 1
        border.color: Theme.color.separator
        opacity: root.active ? 1 : 0
        scale: root.active ? 1 : 0.9
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                style: Tokens.motion.effectsFast
            }
        }

        Behavior on scale {
            Anim {
                style: Tokens.motion.effectsFast
            }
        }

        Label {
            id: label

            anchors.centerIn: parent
            text: root.text
            fontSize: Tokens.fontSize.md
        }
    }
}
