pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.themes

// Background-layer wallpaper from Config.wallpaper.path. Nothing is drawn while the path is empty, so
// another wallpaper tool keeps working until one is set.
Scope {
    id: root

    readonly property string path: Config.wallpaper.path

    function set(path: string): void {
        Config.wallpaper.path = Paths.expand(path);
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen

            required property ShellScreen modelData

            LazyLoader {
                active: root.path !== ""

                PanelWindow {
                    screen: perScreen.modelData
                    anchors {
                        top: true
                        bottom: true
                        left: true
                        right: true
                    }
                    exclusionMode: ExclusionMode.Ignore
                    color: Colors.surface
                    WlrLayershell.layer: WlrLayer.Background
                    WlrLayershell.namespace: "ezshell-wallpaper"

                    Image {
                        anchors.fill: parent
                        source: `file://${root.path}`
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        // Decode at screen size, not the file's full resolution.
                        sourceSize.width: perScreen.modelData.width
                        sourceSize.height: perScreen.modelData.height
                    }
                }
            }
        }
    }

    IpcHandler {
        function set(path: string): void {
            root.set(path);
        }

        function get(): string {
            return root.path;
        }

        target: "wallpaper"
    }
}
