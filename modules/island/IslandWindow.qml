import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services
import qs.modules.island
import qs.modules.island.views

// The island's window: transparent, covering the screen, never resized. Only
// the shape inside it changes, and only the shape takes input.
// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    id: root

    readonly property View view: host.item as View
    // A fullscreen window hides the island, unless the view showing is one
    // that may appear over it (the OSD).
    readonly property bool overFullscreen: Hypr.fullscreen && (view?.showOverFullscreen ?? false)
    readonly property bool retracted: Hypr.fullscreen && !overFullscreen
    // 0 = fully out, 1 = pulled up above the screen edge.
    property real retraction: retracted ? 1 : 0
    // Over a fullscreen (or maximized) window there is no border to hang from,
    // so the island lets go of the edge and floats as a pill: 1 = hanging with
    // concave shoulders, -1 = floating.
    property real shoulder: overFullscreen ? -1 : 1
    readonly property real floatness: (1 - shoulder) / 2

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "ezshell-island"
    // Always the overlay layer, so the OSD can show over a fullscreen window.
    // Changing layer while running did not take effect, so the island stays
    // here and pulls itself up out of the way when a window is fullscreen.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: view?.wantsKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // The island hangs from the inner top edge of the border, floats a little
    // below the screen edge when it is a pill, and pulls up past the screen edge
    // (border and all) when retracted.
    readonly property real top: (Config.border.thickness + (Tokens.island.floatGap - Config.border.thickness) * floatness) * (1 - retraction)

    mask: Region {
        x: Math.floor(shape.x)
        y: Math.max(0, Math.floor(shape.y))
        width: Math.ceil(shape.width)
        height: Math.max(0, Math.ceil(shape.y + shape.height - Math.max(0, Math.floor(shape.y))))
    }

    Behavior on retraction {
        Anim {
            style: Tokens.motion.standard
        }
    }

    Behavior on shoulder {
        Anim {
            style: Tokens.motion.standard
        }
    }

    // Keeps the screen from idling while Keep Awake is on.
    IdleInhibitor {
        window: root
        enabled: KeepAwake.enabled
    }

    // A click anywhere outside closes a dismissible view.
    HyprlandFocusGrab {
        active: root.view?.dismissible ?? false
        windows: [root]
        onCleared: IslandState.close()
    }

    IslandShape {
        id: shape

        // Computed, not anchored: centring by anchor snaps to whole pixels
        // and makes the edges step unevenly while the width animates.
        x: (root.width - width) / 2
        y: root.top - height * root.retraction
        bodyWidth: host.implicitWidth
        bodyHeight: host.implicitHeight
        shoulder: root.shoulder
        opacity: root.retracted ? 0 : 1

        Behavior on opacity {
            Anim {
                style: Tokens.motion.spatial
            }
        }

        HoverHandler {
            onHoveredChanged: IslandState.pointerInside = hovered
        }

        // Below the content, so controls inside a view take their own clicks.
        MouseArea {
            anchors.fill: parent
            enabled: IslandState.inState
            onClicked: IslandState.activate()
        }

        Morph {
            id: host

            x: shape.radius
            width: implicitWidth
            height: implicitHeight
            focus: true
            content: Registry.component(IslandState.current)

            Keys.onEscapePressed: IslandState.back()
        }
    }
}
