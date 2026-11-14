pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// Connection status: Wi-Fi and wired.
Singleton {
    id: root

    readonly property list<NetworkDevice> devices: Networking.devices.values
    readonly property WifiDevice wifi: devices.find(d => d.type === DeviceType.Wifi) as WifiDevice
    readonly property WiredDevice wired: devices.find(d => d.type === DeviceType.Wired) as WiredDevice

    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiConnected: wifi?.connected ?? false
    // With NetworkManager's iwd backend the device reports "connected" but no
    // network in its list is marked connected, so the name comes from nmcli
    // and the network is then looked up by that name.
    property string ssid
    readonly property WifiNetwork wifiNetwork: (wifi?.networks.values.find(n => n.connected) ?? wifi?.networks.values.find(n => n.name === ssid) ?? null) as WifiNetwork
    // 0..1; full when connected but the network's signal is unknown.
    readonly property real strength: !wifiConnected ? 0 : wifiNetwork ? wifiNetwork.signalStrength : 1
    readonly property bool wiredConnected: wired?.connected ?? false
    readonly property bool connected: wifiConnected || wiredConnected

    // Strongest first, the connected one on top. Hidden networks are left out.
    readonly property list<WifiNetwork> networks: (wifi?.networks.values ?? []).filter(n => n.name.length > 0).sort((a, b) => ((b === wifiNetwork) - (a === wifiNetwork)) || (b.signalStrength - a.signalStrength))
    // Set when the last attempt to join a network failed.
    property string failed

    // The device carrying the connection, and its addresses (from nmcli).
    readonly property NetworkDevice primary: wifiConnected ? wifi : wiredConnected ? wired : null
    property string address
    property string gateway
    property string dns

    // Look for networks; only worth doing while the list is on screen.
    function setScanning(scanning: bool): void {
        if (wifi)
            wifi.scannerEnabled = scanning;
    }

    function isCurrent(network: QtObject): bool {
        return network === wifiNetwork;
    }

    function secured(network: QtObject): bool {
        if (!network)
            return false;

        const security = (network as WifiNetwork).security;
        return security !== WifiSecurityType.Open && security !== WifiSecurityType.Owe;
    }

    // A password is needed for a secured network joined for the first time.
    function needsPassword(network: QtObject): bool {
        return secured(network) && !(network as WifiNetwork).known;
    }

    function join(network: QtObject, password: string): void {
        const target = network as WifiNetwork;
        failed = "";
        if (password.length > 0)
            target.connectWithPsk(password);
        else
            target.connect();
    }

    function leave(network: QtObject): void {
        (network as WifiNetwork).disconnect();
    }

    function known(network: QtObject): bool {
        return (network as WifiNetwork)?.known ?? false;
    }

    // Drop the saved password and settings for a network.
    function forget(network: QtObject): void {
        (network as WifiNetwork).forget();
    }

    // Megabits per second; 0 when unknown or unplugged.
    function wiredSpeed(): int {
        return wired?.hasLink ? wired.linkSpeed : 0;
    }

    // Read the addresses again; they arrive a moment after connecting.
    function refreshAddresses(): void {
        if (primary)
            addressProc.running = true;
        else
            address = gateway = dns = "";
    }

    function refreshSsid(): void {
        if (wifiConnected && wifi)
            ssidProc.running = true;
        else
            ssid = "";
    }

    function setWifiEnabled(enabled: bool): void {
        Networking.wifiEnabled = enabled;
    }

    onWifiConnectedChanged: refreshSsid()
    onPrimaryChanged: refreshAddresses()

    Instantiator {
        model: root.networks

        Connections {
            required property WifiNetwork modelData

            function onConnectionFailed(): void {
                root.failed = modelData.name;
            }

            target: modelData
        }
    }
    Component.onCompleted: {
        refreshSsid();
        refreshAddresses();
    }

    Process {
        id: ssidProc

        command: ["nmcli", "-g", "GENERAL.CONNECTION", "device", "show", root.wifi?.name ?? ""]

        stdout: StdioCollector {
            onStreamFinished: root.ssid = text.trim()
        }
    }

    // One line per field, in the order asked for; a field with several
    // values joins them with " | ".
    Process {
        id: addressProc

        command: ["nmcli", "-g", "IP4.ADDRESS,IP4.GATEWAY,IP4.DNS", "device", "show", root.primary?.name ?? ""]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                root.address = (lines[0] ?? "").split(" | ")[0].split("/")[0];
                root.gateway = lines[1] ?? "";
                root.dns = (lines[2] ?? "").split(" | ").join(", ");
            }
        }
    }
}
