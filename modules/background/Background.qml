pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.theme
import qs.components
import qs.services

// The wallpaper, drawn by the shell on every screen. A change of wallpaper
// (or a preview from the selector) crossfades once the new picture has loaded.
Variants {
    model: Config.wallpaper.enabled ? Quickshell.screens : []

    // qmllint disable uncreatable-type
    PanelWindow {
        // qmllint enable uncreatable-type
        id: window

        required property ShellScreen modelData
        // The two layers take turns: the new picture loads into the hidden
        // one, then they swap.
        property bool frontIsA: true

        function show(path: string): void {
            const front = frontIsA ? layerA : layerB;
            const back = frontIsA ? layerB : layerA;
            if (path !== front.path)
                back.path = path;
        }

        screen: modelData
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        exclusionMode: ExclusionMode.Ignore
        color: Theme.color.surface
        WlrLayershell.namespace: "ezshell-background"
        WlrLayershell.layer: WlrLayer.Background

        Component.onCompleted: show(Wallpapers.showing)

        Connections {
            function onShowingChanged(): void {
                window.show(Wallpapers.showing);
            }

            target: Wallpapers
        }

        Layer {
            id: layerA

            front: window.frontIsA
            onLoaded: window.frontIsA = true
        }

        Layer {
            id: layerB

            front: !window.frontIsA
            onLoaded: window.frontIsA = false
        }
    }

    component Layer: Image {
        id: layer

        required property bool front
        property string path

        // The picture is ready while this layer is the hidden one.
        signal loaded

        anchors.fill: parent
        opacity: front ? 1 : 0
        source: path
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        // Swap only once the picture is ready, so there is no blank frame.
        onStatusChanged: {
            if (status === Image.Ready && !front)
                loaded();
        }

        Behavior on opacity {
            Anim {
                style: Tokens.motion.effectsSlow
            }
        }
    }
}
