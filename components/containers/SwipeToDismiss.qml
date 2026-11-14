import QtQuick
import qs.config
import qs.components

// Something that can be dragged sideways out of the way: drag it past
// `threshold` of its width and it slides off and `dismissed` is sent; let go
// short of that and it springs back. It fades as it goes. The content is the
// single child, which it is as big as; give it `anchors.left` and
// `anchors.right` to follow this item's width.
Item {
    id: root

    default property alias content: holder.data
    // How far to drag, as a part of the width.
    property real threshold: 0.4
    property bool interactive: true
    readonly property bool dragging: drag.active

    signal dismissed

    implicitWidth: holder.children.length > 0 ? holder.children[0].implicitWidth : 0
    implicitHeight: holder.children.length > 0 ? holder.children[0].implicitHeight : 0

    Item {
        id: holder

        width: root.width
        height: root.height
        opacity: 1 - Math.min(1, Math.abs(x) / Math.max(1, root.width)) * 0.7

        DragHandler {
            id: drag

            enabled: root.interactive
            yAxis.enabled: false
            onActiveChanged: {
                if (active)
                    return;

                if (Math.abs(holder.x) >= root.width * root.threshold) {
                    leave.to = holder.x > 0 ? root.width : -root.width;
                    leave.start();
                } else {
                    back.start();
                }
            }
        }

        // Past the threshold: carry on out of sight, then tell the owner.
        Anim {
            id: leave

            target: holder
            property: "x"
            style: Tokens.motion.effects
            onFinished: root.dismissed()
        }

        // Short of it: spring back.
        Anim {
            id: back

            target: holder
            property: "x"
            to: 0
            style: Tokens.motion.spatialFast
        }
    }
}
