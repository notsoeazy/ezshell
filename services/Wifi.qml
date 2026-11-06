pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

Singleton {
    id: root

    readonly property bool enabled: Networking.wifiEnabled
    readonly property bool hardwareEnabled: Networking.wifiHardwareEnabled
    readonly property WifiDevice device: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property list<WifiNetwork> networks: root.device?.networks.values ?? []
    readonly property WifiNetwork active: root.networks.find(n => n.connected) ?? null
    // Quickshell 0.3.1 can miss a connection that was already active when the shell started (seen with
    // duplicate NM profiles for one SSID): no network reports connected though the device does. Fall back
    // to the device, with the name unknown ("") and full strength.
    readonly property bool connected: root.active !== null || (root.device?.connected ?? false)
    readonly property string ssid: root.active?.name ?? ""
    readonly property real strength: root.active?.signalStrength ?? (root.connected ? 1 : 0)
    readonly property bool scanning: root.device?.scannerEnabled ?? false
    // Reason of the last failed connect, "" after a success; the UI uses it for a wrong password.
    readonly property string lastError: internal.lastError
    // Saved profiles as { name, uuid }, in range or not (nmcli, see WifiProfiles).
    readonly property var saved: profiles.saved
    // A connect() in flight: the network exists, isn't connected yet and hasn't failed.
    readonly property string pendingName: internal.pending?.name ?? ""
    readonly property bool inFlight: internal.pending !== null && !internal.pending.connected
    readonly property bool connecting: root.inFlight && internal.failReason < 0
    // The last connect failed for missing secrets: the UI asks for a password and retries.
    readonly property bool needsPassword: internal.failReason === ConnectionFailReason.NoSecrets

    function setEnabled(enabled: bool): void {
        Networking.wifiEnabled = enabled;
    }

    function toggle(): void {
        root.setEnabled(!root.enabled);
    }

    // The scanner costs power and radio time, so the UI turns it on only while a network list is open.
    function setScanning(scanning: bool): void {
        if (root.device)
            root.device.scannerEnabled = scanning;
    }

    function secured(network: WifiNetwork): bool {
        return network?.security !== WifiSecurityType.Open;
    }

    function network(name: string): WifiNetwork {
        return root.networks.find(n => n.name === name) ?? null;
    }

    // Known and open networks connect without a password.
    function connect(name: string, password: string): void {
        const network = root.network(name);
        if (!network) {
            console.warn(`[wifi] no network named ${name}`);
            return;
        }
        internal.lastError = "";
        internal.failReason = -1;
        internal.pending = network;
        if (password !== "")
            network.connectWithPsk(password);
        else
            network.connect();
    }

    // Drops the in-flight attempt's state (e.g. when the password page is closed).
    function cancel(): void {
        internal.pending = null;
        internal.failReason = -1;
        internal.lastError = "";
    }

    function disconnect(): void {
        root.active?.disconnect();
    }

    function forget(name: string): void {
        root.network(name)?.forget();
    }

    function refreshSaved(): void {
        profiles.refresh();
    }

    function forgetSaved(uuid: string): void {
        profiles.forget(uuid);
    }

    // Hidden networks never appear in a scan, so Quickshell can't connect to them.
    function connectHidden(ssid: string, password: string): void {
        internal.lastError = "";
        profiles.connectHidden(ssid, password);
    }

    function status(): string {
        if (!root.enabled)
            return "off";
        if (root.connecting)
            return `connecting to ${root.pendingName}`;
        if (!root.connected)
            return root.needsPassword ? `${root.pendingName} needs a password` : "on, not connected";
        return root.active ? `${root.ssid} (${Math.round(root.strength * 100)}%)` : "connected (network unknown)";
    }

    function describe(network: WifiNetwork): string {
        const mark = network.connected ? "*" : " ";
        return `${mark} ${Math.round(network.signalStrength * 100)}% ${network.name}${network.known ? " (known)" : ""}`;
    }

    function list(): string {
        return [...root.networks].sort((a, b) => b.signalStrength - a.signalStrength).map(root.describe).join("\n");
    }

    QtObject {
        id: internal

        property WifiNetwork pending: null
        property string lastError: ""
        // ConnectionFailReason of the last failed connect(), -1 when none.
        property int failReason: -1
    }

    WifiProfiles {
        id: profiles

        onHiddenFailed: internal.lastError = "Couldn't connect to the hidden network"
    }

    Connections {
        function onConnectionFailed(reason: int): void {
            internal.failReason = reason;
            internal.lastError = ConnectionFailReason.toString(reason);
            console.warn(`[wifi] connecting to ${internal.pending?.name} failed: ${internal.lastError}`);
        }

        target: internal.pending
    }

    IpcHandler {
        function toggle(): void {
            root.toggle();
        }

        function setEnabled(enabled: bool): void {
            root.setEnabled(enabled);
        }

        function scan(scanning: bool): void {
            root.setScanning(scanning);
        }

        function connect(name: string, password: string): void {
            root.connect(name, password);
        }

        function disconnect(): void {
            root.disconnect();
        }

        function forget(name: string): void {
            root.forget(name);
        }

        function status(): string {
            return root.status();
        }

        function saved(): string {
            return root.saved.map(p => `${p.uuid} ${p.name}`).join("\n");
        }

        function refreshSaved(): void {
            root.refreshSaved();
        }

        function forgetSaved(uuid: string): void {
            root.forgetSaved(uuid);
        }

        function connectHidden(ssid: string, password: string): void {
            root.connectHidden(ssid, password);
        }

        function list(): string {
            return root.list();
        }

        target: "wifi"
    }
}
