pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth as Bt
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.settings

SettingsPage {
    // Look for new devices only while this page is open.
    Component.onCompleted: Bluetooth.setDiscovering(true)
    Component.onDestruction: Bluetooth.setDiscovering(false)

    Group {
        Layout.fillWidth: true
        title: "Bluetooth"

        ListRow {
            Layout.fillWidth: true
            title: "Bluetooth"
            subtitle: !Bluetooth.available ? "No Bluetooth adapter found" : Bluetooth.name
            icon: "bluetooth"
            interactive: false
            disabled: !Bluetooth.available

            Switch {
                checked: Bluetooth.enabled
                onToggled: Bluetooth.setEnabled(!Bluetooth.enabled)
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Discoverable"
            subtitle: "Let other devices find this computer"
            icon: "visibility"
            interactive: false
            separator: false
            disabled: !Bluetooth.enabled

            Switch {
                checked: Bluetooth.discoverable
                onToggled: Bluetooth.setDiscoverable(!Bluetooth.discoverable)
            }
        }
    }

    Group {
        Layout.fillWidth: true
        visible: Bluetooth.enabled && Bluetooth.paired.length > 0
        title: "My devices"

        Repeater {
            model: Bluetooth.paired

            DeviceRow {
                id: mine

                last: index === Bluetooth.paired.length - 1

                Button {
                    text: mine.modelData?.connected ? "Disconnect" : "Connect"
                    capsule: true
                    disabled: Bluetooth.busy(mine.modelData)
                    onActivated: Bluetooth.toggle(mine.modelData)
                }

                Button {
                    text: "Forget"
                    style: Button.Plain
                    role: Button.Destructive
                    capsule: true
                    onActivated: Bluetooth.forget(mine.modelData)
                }
            }
        }
    }

    Group {
        Layout.fillWidth: true
        visible: Bluetooth.enabled
        title: "Nearby devices"

        Repeater {
            model: Bluetooth.nearby

            DeviceRow {
                id: near

                last: index === Bluetooth.nearby.length - 1

                Button {
                    text: "Pair"
                    capsule: true
                    disabled: Bluetooth.busy(near.modelData)
                    onActivated: Bluetooth.toggle(near.modelData)
                }
            }
        }

        ListRow {
            Layout.fillWidth: true
            visible: Bluetooth.nearby.length === 0
            title: "Looking for devices…"
            interactive: false
            separator: false

            Spinner {}
        }
    }

    component DeviceRow: ListRow {
        id: row

        // Imported under a name, since the service is also called Bluetooth.
        required property Bt.BluetoothDevice modelData
        required property int index
        property bool last

        Layout.fillWidth: true
        title: modelData?.name ?? ""
        subtitle: Bluetooth.status(modelData)
        icon: Symbols.bluetooth(modelData?.icon ?? "")
        interactive: false
        separator: !last

        Spinner {
            visible: Bluetooth.busy(row.modelData)
        }
    }
}
