pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth as Bt
import qs.config
import qs.theme
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

// Bluetooth devices. Click one to connect or disconnect it; a new device is
// paired first.
PanelPage {
    title: "Bluetooth"

    accessory: Switch {
        checked: Bluetooth.enabled
        onToggled: Bluetooth.setEnabled(!Bluetooth.enabled)
    }

    // Look for new devices only while this page is open.
    Component.onCompleted: Bluetooth.setDiscovering(true)
    Component.onDestruction: Bluetooth.setDiscovering(false)

    Label {
        Layout.fillWidth: true
        visible: !Bluetooth.enabled || Bluetooth.devices.length === 0
        text: !Bluetooth.enabled ? "Bluetooth is off." : "Looking for devices…"
        level: Label.Secondary
    }

    List {
        Layout.fillWidth: true
        visible: Bluetooth.enabled && Bluetooth.devices.length > 0
        maxHeight: Tokens.control.row * 7 + Tokens.spacing.xs * 2
        color: Theme.color.fillTertiary
        selectable: false
        model: Bluetooth.devices

        delegate: ListRow {
            id: row

            // Imported under a name, since the service is also called Bluetooth.
            required property Bt.BluetoothDevice modelData
            required property int index

            width: ListView.view.width
            title: modelData?.name ?? ""
            subtitle: !modelData ? "" : modelData.connected ? (modelData.batteryAvailable ? `Connected, battery ${Math.round(modelData.battery * 100)}%` : "Connected") : modelData.paired ? "Not connected" : "New device"
            icon: modelData?.connected ? "bluetooth_connected" : "bluetooth"
            separator: index < Bluetooth.devices.length - 1
            onActivated: Bluetooth.toggle(modelData)

            Spinner {
                visible: Bluetooth.busy(row.modelData)
            }

            Icon {
                visible: row.modelData?.connected ?? false
                name: "check"
                color: Theme.accent
            }
        }
    }
}
