pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.themes

// Background-layer wallpaper from Config.wallpaper.path. Nothing is drawn while the path is empty, so
// another wallpaper tool keeps working until one is set. The Wallpapers service owns the IPC.
Variants {
    model: Quickshell.screens

    Scope {
        id: perScreen

        required property ShellScreen modelData

        LazyLoader {
            active: Config.wallpaper.path !== ""

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

                WallpaperView {
                    anchors.fill: parent
                    path: Config.wallpaper.path
                    // Decode at the screen's device pixels, not the file's full resolution.
                    decodeSize: Qt.size(perScreen.modelData.width * perScreen.modelData.devicePixelRatio, perScreen.modelData.height * perScreen.modelData.devicePixelRatio)
                    transition: Config.wallpaper.transition
                    fill: Config.wallpaper.fill
                }
            }
        }
    }
}
