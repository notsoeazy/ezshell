pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// The laptop battery, if there is one.
Singleton {
    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool available: (device?.ready ?? false) && device.isLaptopBattery
    // 0..1
    readonly property real level: available ? device.percentage : 0
    readonly property bool charging: available && (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge)
    readonly property bool pluggedIn: !UPower.onBattery
    readonly property bool low: available && !pluggedIn && level <= 0.2
}
