import QtQuick
import qs.config

// The shared way for anything to appear and disappear. Set `shown`; the
// content (the child, created lazily) fades, and optionally slides, scales or
// grows into its layout space. It is unloaded once fully hidden.
Item {
    id: root

    enum Collapse {
        None,
        Vertical,
        Horizontal,
        Both
    }

    property bool shown
    default property Component content
    // Where the content slides in from, relative to its resting place.
    property real offsetX
    property real offsetY
    // Scale the content grows from; 1 means no scaling.
    property real fromScale: 1
    // Whether hiding also gives up layout space, so neighbours close the gap.
    property int collapse: Reveal.None
    property Tokens.AnimStyle style: Tokens.motion.spatial

    readonly property Item item: loader.item as Item
    // Movement and size follow `progress`, which may overshoot; opacity
    // follows `fade`, which never does.
    property real progress: shown ? 1 : 0
    property real fade: shown ? 1 : 0
    readonly property real extent: Math.max(0, progress)
    readonly property bool present: shown || fade > 0
    readonly property bool collapsesWidth: collapse === Reveal.Horizontal || collapse === Reveal.Both
    readonly property bool collapsesHeight: collapse === Reveal.Vertical || collapse === Reveal.Both

    implicitWidth: loader.implicitWidth * (collapsesWidth ? extent : 1)
    implicitHeight: loader.implicitHeight * (collapsesHeight ? extent : 1)
    visible: present
    clip: collapse !== Reveal.None

    Behavior on progress {
        Anim {
            style: root.style
        }
    }

    Behavior on fade {
        Anim {
            style: root.shown ? Tokens.motion.effectsSlow : Tokens.motion.effectsFast
        }
    }

    Loader {
        id: loader

        // Content keeps its natural size along a collapsing axis and is
        // clipped, rather than being squeezed.
        width: root.collapsesWidth ? implicitWidth : root.width
        height: root.collapsesHeight ? implicitHeight : root.height
        active: root.present
        sourceComponent: root.content
        opacity: root.fade
        scale: root.fromScale + (1 - root.fromScale) * root.progress

        transform: Translate {
            x: root.offsetX * (1 - root.progress)
            y: root.offsetY * (1 - root.progress)
        }
    }
}
