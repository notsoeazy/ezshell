import QtQuick
import Quickshell
import Quickshell.Wayland

// The part of a screen windows are not placed in: a 1px window along one edge
// with nothing in it and an exclusive zone of `size` pixels. Zones on the same
// edge stack, so the island's strip adds to the top border's. It never refers
// to what is drawn there, so nothing animating can move application windows.
// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    id: root

    // "top", "bottom", "left" or "right".
    required property string edge
    required property real size

    anchors.top: edge !== "bottom"
    anchors.bottom: edge !== "top"
    anchors.left: edge !== "right"
    anchors.right: edge !== "left"
    implicitWidth: 1
    implicitHeight: 1
    exclusiveZone: size
    color: "transparent"
    WlrLayershell.namespace: `ezshell-zone-${edge}`

    mask: Region {}
}
