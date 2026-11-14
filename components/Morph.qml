pragma ComponentBehavior: Bound

import QtQuick
import qs.config

// A container that takes the size of its current content, and when the
// content changes, animates to the new size while crossfading old to new.
// The island, page stacks and anything else that swaps content are built on
// this. Content keeps its natural size and is clipped; it is never squeezed.
Item {
    id: root

    // What to show. Change it to morph.
    property Component content
    property Tokens.AnimStyle style: Tokens.motion.spatial
    // Where content sits while the container is a different size from it.
    property int alignment: Qt.AlignHCenter | Qt.AlignTop
    // With a travel distance, content slides sideways instead of scaling:
    // new content arrives from the `direction` side (1 = right, -1 = left).
    property real travel
    property int direction: 1
    // Turn off when this sits inside another Morph (a view inside the island):
    // it then reports its new size at once and leaves the animating to the
    // outer one. Two nested animations would chase each other.
    property bool animateSize: true

    readonly property Item item: (front === 0 ? slotA.item : slotB.item) as Item
    // Whole pixels, and an even width, so that the settled container and
    // its content land exactly on the pixel grid when centred.
    readonly property real targetWidth: (front === 0 ? slotA : slotB).width
    readonly property real targetHeight: (front === 0 ? slotA : slotB).height
    readonly property bool morphing: widthAnim.running || heightAnim.running
    readonly property real alignX: alignment & Qt.AlignRight ? 1 : alignment & Qt.AlignHCenter ? 0.5 : 0
    readonly property real alignY: alignment & Qt.AlignBottom ? 1 : alignment & Qt.AlignVCenter ? 0.5 : 0

    // Two slots take turns: new content loads into the idle one.
    property int front: 0
    // The slot whose content is still being created, or -1. The switch only
    // happens once it is ready, so the animation never starts on a stall.
    property int pending: -1
    property Component contentA
    property Component contentB
    property real animatedWidth: targetWidth
    property real animatedHeight: targetHeight
    property bool ready

    function swap(): void {
        if (!ready)
            return;

        const idle = front === 0 ? slotB : slotA;
        if (content === (front === 0 ? contentA : contentB)) {
            // Back to what is already showing: drop anything in preparation.
            pending = -1;
            return;
        }

        // If the idle slot still holds this content (it is fading out, or
        // being prepared), reuse it; otherwise load it there.
        if (content !== (front === 0 ? contentB : contentA)) {
            if (front === 0)
                contentB = content;
            else
                contentA = content;
        }
        idle.loaded = true;
        pending = idle.index;
        flipWhenReady();
    }

    function flipWhenReady(): void {
        if (pending < 0)
            return;

        // Wait for the warm-up frames below before switching.
        if ((pending === 0 ? slotA : slotB).prepared)
            warmUp.start();
    }

    implicitWidth: animatedWidth
    implicitHeight: animatedHeight
    clip: true

    onContentChanged: swap()

    Component.onCompleted: {
        // The first content appears at its size with no animation.
        contentA = content;
        ready = true;
    }

    Behavior on animatedWidth {
        enabled: root.ready && root.animateSize

        Anim {
            id: widthAnim

            style: root.style
        }
    }

    Behavior on animatedHeight {
        enabled: root.ready && root.animateSize

        Anim {
            id: heightAnim

            style: root.style
        }
    }

    // Once new content exists it is drawn invisibly for two frames before the
    // switch. Building its text and shapes for the first time is the slowest
    // part, and this keeps that cost out of the animation's first frame.
    FrameAnimation {
        id: warmUp

        property int frames

        function start(): void {
            frames = 0;
            running = true;
        }

        onTriggered: {
            if (root.pending < 0) {
                running = false;
            } else if (++frames >= 2) {
                running = false;
                root.front = root.pending;
                root.pending = -1;
            }
        }
    }

    Slot {
        id: slotA

        index: 0
        source: root.contentA
    }

    Slot {
        id: slotB

        index: 1
        source: root.contentB
    }

    // The Loader sits inside a plain Item: a Loader resizes itself whenever it
    // is moved, which turns bindings on its own position into binding loops.
    component Slot: Item {
        id: slot

        required property int index
        required property Component source
        readonly property Item item: loader.item as Item
        readonly property bool current: root.front === index
        readonly property bool prepared: loader.status === Loader.Ready
        property real fade: current ? 1 : 0
        // Sideways displacement, used when `travel` is set.
        property real offset
        // Set from handlers rather than bound, so loading content (which
        // changes sizes all the way up) cannot re-enter its own binding.
        property bool loaded: current

        x: (root.width - width) * root.alignX + offset
        y: (root.height - height) * root.alignY
        width: Math.ceil(loader.implicitWidth / 2) * 2
        height: Math.ceil(loader.implicitHeight)
        // Drawn (at zero opacity) while being prepared, to warm it up.
        visible: fade > 0 || root.pending === index
        opacity: fade
        scale: root.travel > 0 ? 1 : Tokens.state.swapScale + (1 - Tokens.state.swapScale) * fade
        // Only the current content takes input.
        enabled: current

        onCurrentChanged: {
            if (current)
                loaded = true;
            if (root.travel <= 0)
                return;

            slide.stop();
            if (current) {
                // Start off to the side, unless already on screen mid-exit.
                if (fade <= 0)
                    offset = root.direction * root.travel;
                slide.to = 0;
            } else {
                slide.to = -root.direction * root.travel;
            }
            slide.start();
        }

        // Unload once fully faded out.
        onFadeChanged: {
            if (fade <= 0 && !current && root.pending !== index)
                loaded = false;
        }
        onPreparedChanged: root.flipWhenReady()

        Behavior on fade {
            Anim {
                style: slot.current ? Tokens.motion.effectsSlow : Tokens.motion.effectsFast
            }
        }

        Loader {
            id: loader

            active: slot.loaded && slot.source !== null
            sourceComponent: slot.source
            // Create new content across frames instead of in one long one.
            // The very first content loads at once so there is no empty frame.
            asynchronous: root.ready
        }

        Anim {
            id: slide

            target: slot
            property: "offset"
            style: Tokens.motion.standard
        }
    }
}
