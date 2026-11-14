pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth as Bt

// The default Bluetooth adapter and its devices.
Singleton {
    id: root

    readonly property Bt.BluetoothAdapter adapter: Bt.Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool discovering: adapter?.discovering ?? false
    // Connected first, then paired, then by name. Unnamed devices are left out.
    readonly property list<Bt.BluetoothDevice> devices: (adapter?.devices.values ?? []).filter(d => d.name.length > 0).sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
    readonly property list<Bt.BluetoothDevice> connected: devices.filter(d => d.connected)
    // Devices this computer has been paired with, and new ones in range.
    readonly property list<Bt.BluetoothDevice> paired: devices.filter(d => d.paired)
    readonly property list<Bt.BluetoothDevice> nearby: devices.filter(d => !d.paired)
    // The name other devices see.
    readonly property string name: adapter?.name ?? ""
    readonly property bool discoverable: adapter?.discoverable ?? false

    function setEnabled(enabled: bool): void {
        if (adapter)
            adapter.enabled = enabled;
    }

    // Look for new devices; only worth doing while the list is on screen.
    function setDiscovering(discovering: bool): void {
        if (adapter && adapter.enabled)
            adapter.discovering = discovering;
    }

    // Whether other devices can find this computer.
    function setDiscoverable(discoverable: bool): void {
        if (adapter && adapter.enabled)
            adapter.discoverable = discoverable;
    }

    // Unpair a device.
    function forget(device: QtObject): void {
        (device as Bt.BluetoothDevice).forget();
    }

    // What the device says about itself, for a second line of text.
    function status(device: QtObject): string {
        const d = device as Bt.BluetoothDevice;
        if (!d)
            return "";
        if (d.pairing)
            return "Pairing…";
        if (d.state === Bt.BluetoothDeviceState.Connecting)
            return "Connecting…";
        if (d.connected)
            return d.batteryAvailable ? `Connected, battery ${Math.round(d.battery * 100)}%` : "Connected";
        return d.paired ? "Not connected" : "New device";
    }

    function busy(device: QtObject): bool {
        const d = device as Bt.BluetoothDevice;
        if (!d)
            return false;

        return d.pairing || d.state === Bt.BluetoothDeviceState.Connecting || d.state === Bt.BluetoothDeviceState.Disconnecting;
    }

    // Connect, disconnect, or pair first if the device is new.
    function toggle(device: QtObject): void {
        const d = device as Bt.BluetoothDevice;
        if (d.connected)
            d.disconnect();
        else if (d.paired)
            d.connect();
        else
            d.pair();
    }
}
