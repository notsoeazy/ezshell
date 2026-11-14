import QtQuick
import qs.config
import qs.theme
import qs.components

// Overlay scrollbar for any Flickable (ScrollView, List, a ListView). Appears
// while scrolling or hovered, then fades. Takes no layout space.
Item {
    id: root

    required property Flickable flickable
    readonly property bool needed: flickable.visibleArea.heightRatio < 1
    readonly property bool engaged: flickable.moving || hover.hovered || drag.pressed
    property bool shown

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    width: Tokens.spacing.md
    z: 1
    opacity: needed && shown ? 1 : 0
    visible: needed

    onEngagedChanged: {
        if (engaged) {
            hide.stop();
            shown = true;
        } else {
            hide.restart();
        }
    }

    Behavior on opacity {
        Anim {}
    }

    Timer {
        id: hide

        interval: Tokens.state.scrollbarHide
        onTriggered: root.shown = false
    }

    HoverHandler {
        id: hover
    }

    Rectangle {
        id: thumb

        anchors.right: parent.right
        anchors.rightMargin: Tokens.spacing.xxs
        y: root.flickable.visibleArea.yPosition * root.height
        width: hover.hovered || drag.pressed ? Tokens.spacing.sm : Tokens.control.track
        height: Math.max(Tokens.control.minTarget, root.flickable.visibleArea.heightRatio * root.height)
        radius: width / 2
        color: Theme.color.labelTertiary

        Behavior on width {
            Anim {
                style: Tokens.motion.effectsFast
            }
        }
    }

    MouseArea {
        id: drag

        function scrollTo(y: real): void {
            const track = root.height - thumb.height;
            const fraction = track > 0 ? Math.max(0, Math.min(1, (y - thumb.height / 2) / track)) : 0;
            root.flickable.contentY = root.flickable.originY + fraction * (root.flickable.contentHeight - root.flickable.height);
        }

        anchors.fill: parent
        preventStealing: true
        onPressed: event => scrollTo(event.y)
        onPositionChanged: event => scrollTo(event.y)
    }
}
