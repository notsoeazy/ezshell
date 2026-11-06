pragma ComponentBehavior: Bound

import QtQuick
import qs.themes

// One screen's wallpaper. Two slots take turns: a new image loads into the hidden slot, and the
// transition starts only once it is decoded, so the old image stays up meanwhile (never a black frame).
Item {
    id: root

    required property string path
    // Decode size in device pixels; "center" ignores it to show the image at its own size.
    required property size decodeSize
    // "fade", "wipe" or "none" (Config.wallpaper.transition).
    required property string transition
    // "crop", "fit" or "center" (Config.wallpaper.fill).
    required property string fill
    // Slot on screen (0 or 1); the other one loads the next image.
    property int front: 0
    // No transition for the first image after start.
    property bool first: true
    readonly property Slot frontSlot: root.front === 0 ? slotA : slotB
    readonly property Slot backSlot: root.front === 0 ? slotB : slotA
    readonly property int fillMode: root.fill === "fit" ? Image.PreserveAspectFit : root.fill === "center" ? Image.Pad : Image.PreserveAspectCrop

    // A newer path cuts a running transition short: it ends where it was headed, then the newest loads.
    function load(): void {
        if (swap.running) {
            swap.stop();
            root.settle();
        }
        root.backSlot.source = root.path !== "" ? `file://${root.path}` : "";
        root.tryShow();
    }

    // Runs on load and on every status change, since a cached image can be Ready at once.
    function tryShow(): void {
        const slot = root.backSlot;
        if (swap.running || slot.source.toString() === "" || slot.status !== Image.Ready)
            return;
        slot.z = 1;
        root.frontSlot.z = 0;
        if (root.first || root.transition === "none") {
            root.settle();
            return;
        }
        slot.shown = 0;
        swap.target = slot;
        swap.start();
    }

    function settle(): void {
        const old = root.frontSlot;
        root.backSlot.shown = 1;
        root.front = 1 - root.front;
        root.first = false;
        old.source = "";
    }

    onPathChanged: root.load()
    Component.onCompleted: root.load()

    Slot {
        id: slotA
    }

    Slot {
        id: slotB
    }

    NumberAnimation {
        id: swap

        property: "shown"
        from: 0
        to: 1
        duration: Appearance.anim.scaled(Appearance.anim.wallpaper)
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.standard
        onFinished: root.settle()
    }

    // shown: 0 → 1 during a transition; fade drives opacity, wipe the clip width from the left.
    component Slot: Item {
        id: slot

        property real shown: 1
        property alias source: image.source
        readonly property int status: image.status

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: root.transition === "wipe" ? root.width * slot.shown : root.width
        opacity: root.transition === "fade" ? slot.shown : 1
        clip: root.transition === "wipe"
        onStatusChanged: {
            if (slot.status === Image.Error)
                console.warn(`[wallpaper] can't load ${slot.source}`);
            root.tryShow();
        }

        Image {
            id: image

            width: root.width
            height: root.height
            fillMode: root.fillMode
            asynchronous: true
            sourceSize: root.fill === "center" ? undefined : root.decodeSize
        }
    }
}
