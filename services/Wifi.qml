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
    // Saved NetworkManager profiles as { name, uuid }, in range or not. Quickshell only lists in-range
    // networks, so these come from nmcli; refreshSaved() re-reads them (on demand, not polled).
    readonly property var saved: internal.saved
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
        savedReader.exec(["nmcli", "--terse", "--fields", "UUID,TYPE,NAME", "connection", "show"]);
    }

    // Deletes one profile by UUID, so duplicate profiles for one SSID can be removed separately.
    function forgetSaved(uuid: string): void {
        profileAction.exec(["nmcli", "connection", "delete", "uuid", uuid]);
    }

    // Hidden networks never appear in a scan, so Quickshell can't connect to them. The password goes
    // through stdin (--ask), not argv, so it never shows up in the process list.
    function connectHidden(ssid: string, password: string): void {
        internal.lastError = "";
        internal.hiddenPassword = password;
        hiddenConnect.exec(["nmcli", "--ask", "device", "wifi", "connect", ssid, "hidden", "yes"]);
    }

    // nmcli --terse escapes ":" inside fields as "\:"; NAME is last so only the first two separators split.
    function parseSaved(text: string): var {
        const rows = text.trim().split("\n").filter(line => line !== "");
        const parse = line => {
            const [uuid, type, ...rest] = line.split(":");
            return {
                uuid: uuid,
                type: type,
                name: rest.join(":").replace(/\\:/g, ":")
            };
        };
        return rows.map(parse).filter(p => p.type === "802-11-wireless").map(p => ({
                    name: p.name,
                    uuid: p.uuid
                }));
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
        property var saved: []
        property string hiddenPassword: ""
    }

    Process {
        id: savedReader

        stdout: StdioCollector {
            onStreamFinished: internal.saved = root.parseSaved(text)
        }
    }

    Process {
        id: profileAction

        onExited: code => {
            if (code !== 0)
                console.warn(`[wifi] nmcli connection delete exited with ${code}`);
            root.refreshSaved();
        }
    }

    Process {
        id: hiddenConnect

        stdinEnabled: true
        onStarted: {
            hiddenConnect.write(internal.hiddenPassword + "\n");
            internal.hiddenPassword = "";
        }
        onExited: code => {
            if (code !== 0)
                internal.lastError = "Couldn't connect to the hidden network";
            root.refreshSaved();
        }
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
