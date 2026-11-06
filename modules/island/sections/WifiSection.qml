pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import qs.components
import qs.services
import qs.state
import qs.themes
import qs.utils

// Wi-Fi: network list while scanning; a password sub-page when a connect needs secrets (ISLAND.md).
ColumnLayout {
    id: root

    // The network the user picked; drives the password page and the collapse on success.
    property string target: ""
    readonly property bool askingPassword: Visibility.stack[Visibility.stack.length - 1] === "password"
    readonly property list<WifiNetwork> networks: root.sorted(Wifi.networks)

    // Connected first, then by signal; hidden networks (no name) are left to the settings app.
    function sorted(networks: list<WifiNetwork>): list<WifiNetwork> {
        const order = (a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength);
        return [...networks].filter(n => n.name !== "").sort(order);
    }

    // Try without a password first; the password page appears only if that fails for missing secrets.
    function choose(network: WifiNetwork): void {
        if (network.connected) {
            Wifi.disconnect();
            return;
        }
        root.target = network.name;
        Wifi.connect(network.name, "");
    }

    function subtitle(network: WifiNetwork): string {
        if (network.connected)
            return "Connected";
        if (Wifi.connecting && Wifi.pendingName === network.name)
            return "Connecting…";
        return network.known ? "Saved" : Wifi.secured(network) ? "Secured" : "Open";
    }

    spacing: Appearance.island.expanded.gap
    Component.onCompleted: Wifi.setScanning(true)
    Component.onDestruction: Wifi.setScanning(false)

    Connections {
        function onNeedsPasswordChanged(): void {
            if (Wifi.needsPassword && Wifi.pendingName === root.target && !root.askingPassword)
                Visibility.push("password");
        }

        // Success: the picked network finished connecting without an error. Collapse (ISLAND.md).
        function onConnectingChanged(): void {
            if (!Wifi.connecting && root.target !== "" && Wifi.pendingName === root.target && Wifi.lastError === "")
                Visibility.close();
        }

        target: Wifi
    }

    Loader {
        Layout.fillWidth: true
        active: root.askingPassword
        visible: active
        sourceComponent: Component {
            WifiPassword {
                network: root.target
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: !root.askingPassword && !Wifi.enabled
        text: "Wi‑Fi is off"
        color: Colors.surfaceVariantFg
    }

    ListView {
        Layout.fillWidth: true
        implicitHeight: Math.min(contentHeight, Appearance.island.expanded.listMaxHeight)
        visible: !root.askingPassword && Wifi.enabled
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: ScriptModel {
            values: [...root.networks]
        }

        delegate: ListRow {
            id: row

            required property WifiNetwork modelData

            width: ListView.view.width
            // A scan can drop a network while its row is still alive, so modelData may be null briefly.
            icon: Icons.wifi(true, true, row.modelData?.signalStrength ?? 0)
            title: row.modelData?.name ?? ""
            subtitle: row.modelData ? root.subtitle(row.modelData) : ""
            active: row.modelData?.connected ?? false
            onActivated: root.choose(row.modelData)

            MaterialIcon {
                visible: row.modelData !== null && Wifi.secured(row.modelData)
                text: "lock"
                size: Appearance.font.size.large
                color: Colors.surfaceVariantFg
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: !root.askingPassword && Wifi.lastError !== "" && !Wifi.needsPassword
        text: `Couldn't connect: ${Wifi.lastError}`
        color: Colors.error
    }

    SettingsLink {
        label: "Wi‑Fi settings"
        page: "wifi"
    }
}
