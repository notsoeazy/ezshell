pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.capture

// Choosing what to capture: a window over every screen while the Capture
// service is asking.
Variants {
    model: Capture.picking.length > 0 ? Quickshell.screens : []

    // qmllint disable uncreatable-type
    PanelWindow {
        // qmllint enable uncreatable-type
        id: window

        required property ShellScreen modelData

        screen: modelData
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "ezshell-capture"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        PickerArea {
            anchors.fill: parent
            screen: window.modelData
        }
    }
}
