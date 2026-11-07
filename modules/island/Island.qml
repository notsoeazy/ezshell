pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services
import qs.state
import qs.themes

Scope {
    id: root

    // Never auto-collapse while a password is being typed or a connect or pair is in flight, or while a polkit
    // prompt covers the panel.
    readonly property bool busy: Wifi.connecting || Bt.busy || Polkit.active
    readonly property bool holdOpen: Visibility.stack.includes("password") || root.busy
    // Exclusive keyboard only for the password page, and only when opened by keybind/IPC: a click
    // already gives the island focus, and Exclusive would lock the keyboard for nothing.
    readonly property bool grabKeys: Visibility.stack.includes("password") && !Visibility.openedByPointer

    // The monitor focused when a polkit request arrives shows the prompt, until polkit has none left.
    property string authScreen: ""

    // Workspace or monitor focus changes collapse whatever is open (docs/ISLAND.md, Focus and dismissal).
    function collapse(): void {
        if (Visibility.panel !== "" && !root.holdOpen)
            Visibility.close();
    }

    Transients {}

    Connections {
        function onActiveChanged(): void {
            if (Polkit.active)
                root.authScreen = Hyprland.focusedMonitor?.name ?? "";
        }

        target: Polkit
    }

    // A region shot waits until the island's "Drag to select" pill has collapsed, so it isn't in the picture.
    Binding {
        target: Capture
        property: "settle"
        value: Appearance.anim.scaled(Appearance.anim.islandCollapse + Appearance.anim.islandFadeOut)
    }

    // Themes can't read config, so the user's animation speed is pushed into the tokens here.
    Binding {
        target: Appearance.anim
        property: "speed"
        value: Config.animations.speed
    }

    Connections {
        function onFocusedWorkspaceChanged(): void {
            root.collapse();
        }

        function onFocusedScreenChanged(): void {
            root.collapse();
        }

        target: Hypr
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen

            required property ShellScreen modelData

            // Reserves the resting island's space. The island window itself ignores exclusive zones,
            // so tiled windows never move while it morphs.
            PanelWindow {
                screen: perScreen.modelData
                anchors.top: true
                implicitWidth: 1
                implicitHeight: Appearance.island.margin + Appearance.island.height
                // Released while the island is hidden, so windows take the space.
                exclusiveZone: Visibility.islandHidden ? 0 : implicitHeight
                color: Colors.transparent
                mask: Region {}
                WlrLayershell.namespace: "ezshell-island-zone"
            }

            // Sized for the largest mode plus overshoot room, so the morph never resizes the window.
            PanelWindow {
                id: overlay

                readonly property bool typing: ["launcher", "wallpapers", "polkit", "capture", "keybinds"].includes(surface.mode)
                readonly property bool expanded: Visibility.isSection(surface.mode)
                readonly property int typingFocus: WlrKeyboardFocus.Exclusive
                readonly property int expandedFocus: root.grabKeys ? overlay.typingFocus : WlrKeyboardFocus.OnDemand
                readonly property int sectionFocus: overlay.expanded ? overlay.expandedFocus : WlrKeyboardFocus.None

                screen: perScreen.modelData
                anchors.top: true
                implicitWidth: Appearance.island.maxWidth + 2 * Appearance.island.overshootMargin
                implicitHeight: Appearance.island.windowHeight
                exclusionMode: ExclusionMode.Ignore
                color: Colors.transparent
                // Only the pill takes input; the rest of the window is click-through.
                mask: Region {
                    item: surface
                }
                // Hyprland hides Top surfaces under fullscreen and keeps the game on direct scanout. Overlay
                // draws above fullscreen but blocks scanout, so it is used only while a transient shows.
                // The polkit prompt always takes Overlay: nothing may cover a password prompt but the lock screen.
                WlrLayershell.layer: surface.elevated || surface.authHere ? WlrLayer.Overlay : WlrLayer.Top
                WlrLayershell.namespace: "ezshell-island"
                // None at rest, OnDemand while expanded, Exclusive for the search fields and the polkit prompt.
                WlrLayershell.keyboardFocus: overlay.typing ? overlay.typingFocus : overlay.sectionFocus

                // Clicking outside an open panel closes it. A clear that arrives while the pill is still
                // morphing open comes from the click that opened it, so it's ignored (one guard, no timers).
                HyprlandFocusGrab {
                    windows: [overlay]
                    active: overlay.typing || overlay.expanded
                    onCleared: {
                        if (surface.settled && !root.holdOpen)
                            Visibility.close();
                    }
                }

                // A window going fullscreen on this monitor collapses an open section.
                Connections {
                    function onFullscreenChanged(): void {
                        if (surface.panelHere)
                            root.collapse();
                    }

                    target: surface
                }

                // Keep awake: an inhibitor needs a surface, and the island's is always mapped.
                IdleInhibitor {
                    window: overlay
                    enabled: Idle.inhibited
                }

                Surface {
                    id: surface

                    screenName: perScreen.modelData.name
                    authScreen: root.authScreen
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
