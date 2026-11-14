import QtQuick
import QtQuick.Shapes
import qs.config
import qs.theme
import qs.components

// The island's outline: a body hanging from the top edge, joined to it by
// concave shoulders, with rounded bottom corners. The shoulders sit outside
// the body, so the item is two radii wider than `bodyWidth`.
//
// `shoulder` is how the top corners curve: 1 is the concave shoulders that join
// the edge, 0 is square corners, -1 is rounded convex corners, which makes the
// body a floating pill (the shoulders' room is left empty). In between, the
// corner shrinks to nothing and grows out the other way, so the shape morphs
// without a jump.
Shape {
    id: root

    required property real bodyWidth
    required property real bodyHeight
    property real shoulder: 1
    readonly property real radius: Tokens.island.radius
    // A body shorter than two radii gets shallower curves, so the idle shape
    // stays clean.
    readonly property real radiusY: Math.min(radius, bodyHeight / 2)
    // The top corners' size now: nothing at 0, a full radius at either end.
    readonly property real cornerX: Math.max(0.01, radius * Math.abs(shoulder))
    readonly property real cornerY: Math.max(0.01, radiusY * Math.abs(shoulder))
    readonly property int cornerSweep: shoulder >= 0 ? PathArc.Clockwise : PathArc.Counterclockwise

    width: bodyWidth + radius * 2
    height: bodyHeight
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        // A hairline while it floats, so a pill over a page the same colour as
        // the island does not disappear.
        strokeWidth: 1
        strokeColor: Qt.alpha(Theme.color.separator, Math.max(0, -root.shoulder))
        fillColor: Theme.color.island
        startX: root.radius * (1 - root.shoulder)
        startY: 0

        // Left top corner, into the body's side.
        PathArc {
            relativeX: root.radius * root.shoulder
            relativeY: root.cornerY
            radiusX: root.cornerX
            radiusY: root.cornerY
            direction: root.cornerSweep
        }

        PathLine {
            relativeX: 0
            relativeY: root.bodyHeight - root.radiusY - root.cornerY
        }

        // Bottom-left corner.
        PathArc {
            relativeX: root.radius
            relativeY: root.radiusY
            radiusX: root.radius
            radiusY: root.radiusY
            direction: PathArc.Counterclockwise
        }

        PathLine {
            relativeX: root.bodyWidth - root.radius * 2
            relativeY: 0
        }

        // Bottom-right corner.
        PathArc {
            relativeX: root.radius
            relativeY: -root.radiusY
            radiusX: root.radius
            radiusY: root.radiusY
            direction: PathArc.Counterclockwise
        }

        PathLine {
            relativeX: 0
            relativeY: -(root.bodyHeight - root.radiusY - root.cornerY)
        }

        // Right top corner, back out to the edge or round into the top.
        PathArc {
            relativeX: root.radius * root.shoulder
            relativeY: -root.cornerY
            radiusX: root.cornerX
            radiusY: root.cornerY
            direction: root.cornerSweep
        }

        Behavior on fillColor {
            ColorAnim {}
        }
    }
}
