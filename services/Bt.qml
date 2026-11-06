pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

// Quickshell has no pairing agent, so devices that need a PIN or passkey can't pair from here yet.
Singleton {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool available: root.adapter !== null
    readonly property bool enabled: root.adapter?.enabled ?? false
    readonly property bool blocked: root.adapter?.state === BluetoothAdapterState.Blocked
    readonly property bool discovering: root.adapter?.discovering ?? false
    readonly property list<BluetoothDevice> devices: root.adapter?.devices.values ?? []
    readonly property list<BluetoothDevice> connected: root.devices.filter(d => d.connected)
    readonly property list<BluetoothDevice> paired: root.devices.filter(d => d.paired)
    // A pair or connect in flight; the island stays open until it finishes.
    readonly property bool busy: root.devices.some(d => d.pairing || root.transitional(d.state))
    // Name of the first connected device, for the Bluetooth tile subtitle.
    readonly property string connectedName: root.connected[0]?.name ?? ""

    // BlueZ can't power a soft-blocked adapter, and Quickshell can't lift an rfkill block, so this shells out once.
    // Human-readable state, shared by the island section and the settings page.
    function stateText(device: BluetoothDevice): string {
        let state = device.connected ? "Connected" : device.paired ? "Paired" : "Not paired";
        if (device.pairing)
            state = "Pairing…";
        else if (device.state === BluetoothDeviceState.Connecting)
            state = "Connecting…";
        return device.batteryAvailable ? `${state} · ${Math.round(device.battery * 100)}%` : state;
    }

    function transitional(state: int): bool {
        return state === BluetoothDeviceState.Connecting || state === BluetoothDeviceState.Disconnecting;
    }

    function setEnabled(enabled: bool): void {
        if (!root.adapter)
            return;
        if (enabled && root.blocked)
            unblock.exec(["rfkill", "unblock", "bluetooth"]);
        else
            root.adapter.enabled = enabled;
    }

    function toggle(): void {
        root.setEnabled(!root.enabled);
    }

    // Discovery costs power, so the UI turns it on only while a device list is open.
    function setDiscovering(discovering: bool): void {
        if (root.adapter && (root.enabled || !discovering))
            root.adapter.discovering = discovering;
    }

    function device(address: string): BluetoothDevice {
        return root.devices.find(d => d.address === address) ?? null;
    }

    // Pairs first when needed; connecting an unpaired device fails in BlueZ.
    function connect(address: string): void {
        const device = root.device(address);
        if (!device)
            console.warn(`[bt] no device ${address}`);
        else if (!device.paired)
            device.pair();
        else
            device.connect();
    }

    function disconnect(address: string): void {
        root.device(address)?.disconnect();
    }

    function forget(address: string): void {
        root.device(address)?.forget();
    }

    function status(): string {
        if (!root.available)
            return "no adapter";
        if (!root.enabled)
            return root.blocked ? "off (rfkill blocked)" : "off";
        return root.connected.length > 0 ? `on, connected: ${root.connected.map(d => d.name).join(", ")}` : "on";
    }

    function list(): string {
        const line = d => `${d.connected ? "*" : " "} ${d.address} ${d.name}${d.paired ? " (paired)" : ""}`;
        return root.devices.map(line).join("\n");
    }

    Process {
        id: unblock

        onExited: code => {
            if (code !== 0)
                console.warn(`[bt] rfkill unblock exited with ${code}`);
            else if (root.adapter)
                root.adapter.enabled = true;
        }
    }

    IpcHandler {
        function toggle(): void {
            root.toggle();
        }

        function setEnabled(enabled: bool): void {
            root.setEnabled(enabled);
        }

        function scan(discovering: bool): void {
            root.setDiscovering(discovering);
        }

        function connect(address: string): void {
            root.connect(address);
        }

        function disconnect(address: string): void {
            root.disconnect(address);
        }

        function forget(address: string): void {
            root.forget(address);
        }

        function status(): string {
            return root.status();
        }

        function list(): string {
            return root.list();
        }

        function paired(): string {
            return root.paired.map(d => `${d.address} ${d.name}`).join("\n");
        }

        target: "bt"
    }
}
