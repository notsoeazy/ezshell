pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Networking as Net
import qs.config
import qs.theme
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils

// Nearby Wi-Fi networks. Click one to join it; a network that needs a
// password asks for it in place.
PanelPage {
    id: root

    // The network waiting for a password, if any.
    property Net.WifiNetwork pending

    function choose(network: QtObject): void {
        if (Network.isCurrent(network)) {
            Network.leave(network);
        } else if (Network.needsPassword(network)) {
            pending = pending === network ? null : network;
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

    title: "Wi-Fi"

    accessory: Switch {
        checked: Network.wifiEnabled
        onToggled: Network.setWifiEnabled(!Network.wifiEnabled)
    }

    // Scan only while this page is open.
    Component.onCompleted: Network.setScanning(true)
    Component.onDestruction: Network.setScanning(false)

    Label {
        Layout.fillWidth: true
        visible: !Network.wifiEnabled || Network.networks.length === 0
        text: !Network.wifiEnabled ? "Wi-Fi is off." : "Looking for networks…"
        level: Label.Secondary
    }

    Reveal {
        Layout.fillWidth: true
        shown: Network.failed.length > 0
        collapse: Reveal.Vertical

        Label {
            text: `Couldn't join ${Network.failed}. Check the password and try again.`
            color: Theme.color.red
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
        }
    }

    Reveal {
        Layout.fillWidth: true
        shown: root.pending !== null
        collapse: Reveal.Vertical

        RowLayout {
            spacing: Tokens.spacing.sm

            TextField {
                id: password

                Layout.fillWidth: true
                size: Tokens.size.xl
                secure: true
                leadingIcon: "lock"
                placeholder: `Password for ${root.pending?.name ?? ""}`
                onAccepted: root.submit(text)
                Component.onCompleted: focusInput()
            }

            Button {
                text: "Join"
                style: Button.Filled
                size: Tokens.size.xl
                disabled: password.text.length === 0
                onActivated: root.submit(password.text)
            }
        }
    }

    List {
        Layout.fillWidth: true
        visible: Network.wifiEnabled && Network.networks.length > 0
        maxHeight: Tokens.control.row * 7 + Tokens.spacing.xs * 2
        color: Theme.color.fillTertiary
        selectable: false
        model: Network.networks

        delegate: ListRow {
            id: row

            // Imported under a name, since the service is also called Network.
            required property Net.WifiNetwork modelData
            required property int index
            readonly property bool current: Network.isCurrent(modelData)

            width: ListView.view.width
            // A network can vanish from a scan a moment before its row does.
            title: modelData?.name ?? ""
            subtitle: current ? "Connected" : root.pending === modelData ? "Enter the password above" : ""
            icon: Symbols.level("wifi", modelData?.signalStrength ?? 0)
            separator: index < Network.networks.length - 1
            onActivated: root.choose(modelData)

            Spinner {
                visible: row.modelData?.stateChanging ?? false
            }

            Icon {
                visible: row.current
                name: "check"
                color: Theme.accent
            }

            Icon {
                visible: Network.secured(row.modelData)
                name: "lock"
                size: Tokens.icon.sm
                level: Icon.Tertiary
            }
        }
    }
}
