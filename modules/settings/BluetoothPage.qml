pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.themes
import qs.utils

ColumnLayout {
    id: root

    spacing: Appearance.settings.padding

    Section {
        title: "Bluetooth"

        SettingRow {
            icon: Icons.bluetooth(Bt.enabled, Bt.connected.length > 0)
            label: Bt.available ? "Bluetooth" : "No Bluetooth adapter"
            sublabel: Bt.status()

            StyledSwitch {
                enabled: Bt.available
                checked: Bt.enabled
                onToggled: enabled => Bt.setEnabled(enabled)
            }
        }
    }

    Section {
        title: "Devices"
        description: "Devices that need a PIN or passkey can't pair here yet; pair them once with bluetoothctl."

        Repeater {
            model: Bt.devices

            SettingRow {
                id: device

                required property var modelData
                icon: Icons.btDevice(device.modelData.icon)
                label: device.modelData.name
                sublabel: Bt.stateText(device.modelData)

                StyledButton {
                    visible: device.modelData.paired
                    text: "Forget"
                    icon: "delete"
                    onClicked: Bt.forget(device.modelData.address)
                }
            }
        }

        StyledText {
            visible: Bt.devices.length === 0
            text: Bt.enabled ? "No devices" : "Turn Bluetooth on to see devices"
            color: Colors.surfaceVariantFg
        }
    }
}
