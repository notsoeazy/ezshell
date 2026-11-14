pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Networking as Net
import qs.config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.settings

SettingsPage {
    id: root

    // Networks joined before, and the rest; the one in use is in neither.
    readonly property list<Net.WifiNetwork> saved: Network.networks.filter(n => Network.known(n) && !Network.isCurrent(n))
    readonly property list<Net.WifiNetwork> others: Network.networks.filter(n => !Network.known(n) && !Network.isCurrent(n))
    // The network waiting for a password, if any.
    property Net.WifiNetwork pending

    function join(network: QtObject): void {
        if (Network.needsPassword(network)) {
            pending = network as Net.WifiNetwork;
        } else {
            pending = null;
            Network.join(network, "");
        }
    }

    function submit(password: string): void {
        if (pending === null || password.length === 0)
            return;

        Network.join(pending, password);
        pending = null;
    }

    // Scan only while this page is open.
    Component.onCompleted: {
        Network.setScanning(true);
        Network.refreshAddresses();
    }
    Component.onDestruction: Network.setScanning(false)

    Group {
        Layout.fillWidth: true
        title: "Wi-Fi"
        note: Network.failed.length > 0 ? `Couldn't join ${Network.failed}. Check the password and try again.` : ""

        ListRow {
            Layout.fillWidth: true
            title: "Wi-Fi"
            icon: "wifi"
            interactive: false
            separator: Network.wifiConnected

            Switch {
                checked: Network.wifiEnabled
                onToggled: Network.setWifiEnabled(!Network.wifiEnabled)
            }
        }

        ListRow {
            Layout.fillWidth: true
            visible: Network.wifiConnected
            title: Network.ssid.length > 0 ? Network.ssid : "Connected"
            subtitle: `Connected, signal ${Math.round(Network.strength * 100)}%`
            icon: Symbols.level("wifi", Network.strength)
            interactive: false
            separator: false

            Icon {
                visible: Network.secured(Network.wifiNetwork)
                name: "lock"
                size: Tokens.icon.sm
                level: Icon.Tertiary
            }

            Button {
                text: "Disconnect"
                capsule: true
                disabled: Network.wifiNetwork === null
                onActivated: Network.leave(Network.wifiNetwork)
            }
        }
    }

    Group {
        Layout.fillWidth: true
        visible: Network.wifiEnabled && root.saved.length > 0
        title: "Known networks"

        Repeater {
            model: root.saved

            NetworkRow {
                id: known

                last: index === root.saved.length - 1

                Button {
                    text: "Forget"
                    style: Button.Plain
                    role: Button.Destructive
                    capsule: true
                    onActivated: Network.forget(known.modelData)
                }
            }
        }
    }

    Group {
        Layout.fillWidth: true
        visible: Network.wifiEnabled
        title: "Other networks"

        Repeater {
            model: root.others

            NetworkRow {
                last: index === root.others.length - 1
            }
        }

        ListRow {
            Layout.fillWidth: true
            visible: root.others.length === 0
            title: "Looking for networks…"
            interactive: false
            separator: false

            Spinner {}
        }
    }

    Group {
        Layout.fillWidth: true
        visible: Network.wired !== null
        title: "Wired"

        ValueRow {
            Layout.fillWidth: true
            title: "Ethernet"
            subtitle: Network.wired?.name ?? ""
            icon: "lan"
            separator: false
            value: !Network.wiredConnected ? (Network.wiredSpeed() > 0 ? "Not connected" : "Cable unplugged") : Network.wiredSpeed() > 0 ? `Connected, ${Network.wiredSpeed()} Mb/s` : "Connected"
        }
    }

    Group {
        Layout.fillWidth: true
        visible: Network.primary !== null
        title: "Details"

        ValueRow {
            Layout.fillWidth: true
            title: "Interface"
            value: Network.primary?.name ?? ""
        }

        ValueRow {
            Layout.fillWidth: true
            title: "IP address"
            value: Network.address
        }

        ValueRow {
            Layout.fillWidth: true
            title: "Router"
            value: Network.gateway
        }

        ValueRow {
            Layout.fillWidth: true
            title: "DNS"
            separator: false
            value: Network.dns
        }
    }

    // A network that can be joined; one that needs a password asks for it in
    // the row.
    component NetworkRow: ListRow {
        id: row

        // Imported under a name, since the service is also called Network.
        required property Net.WifiNetwork modelData
        required property int index
        property bool last
        readonly property bool asking: root.pending !== null && root.pending === modelData

        Layout.fillWidth: true
        // A network can vanish from a scan a moment before its row does.
        title: modelData?.name ?? ""
        icon: Symbols.level("wifi", modelData?.signalStrength ?? 0)
        interactive: false
        separator: !last

        Spinner {
            visible: row.modelData?.stateChanging ?? false
        }

        Icon {
            visible: Network.secured(row.modelData) && !row.asking
            name: "lock"
            size: Tokens.icon.sm
            level: Icon.Tertiary
        }

        TextField {
            id: password

            implicitWidth: Tokens.spacing.xxxl * 6
            visible: row.asking
            secure: true
            leadingIcon: "lock"
            placeholder: "Password"
            onAccepted: root.submit(text)
            onVisibleChanged: {
                if (visible)
                    focusInput();
            }
        }

        Button {
            text: "Join"
            style: row.asking ? Button.Filled : Button.Gray
            capsule: true
            disabled: row.asking && password.text.length === 0
            onActivated: row.asking ? root.submit(password.text) : root.join(row.modelData)
        }
    }
}
