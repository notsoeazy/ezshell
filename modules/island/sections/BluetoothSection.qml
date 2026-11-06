pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.components
import qs.services
import qs.themes
import qs.utils

// Bluetooth: devices while discovering. Pairing works only for devices that need no code.
ColumnLayout {
    id: root

    // Connected first, then paired, then nearby; unnamed devices are skipped.
    readonly property list<BluetoothDevice> devices: root.sorted(Bt.devices)

    // BlueZ names a device after its address ("55-C7-…") until it learns the real name.
    function named(device: BluetoothDevice): bool {
        return device.name !== "" && device.name !== device.address.replace(/:/g, "-");
    }

    function sorted(devices: list<BluetoothDevice>): list<BluetoothDevice> {
        const byRank = (a, b) => root.rank(b) - root.rank(a) || a.name.localeCompare(b.name);
        return [...devices].filter(root.named).sort(byRank);
    }

    function rank(device: BluetoothDevice): int {
        return device.connected ? 2 : device.paired ? 1 : 0;
    }

    function choose(device: BluetoothDevice): void {
        if (device.connected)
            Bt.disconnect(device.address);
        else
            Bt.connect(device.address);
    }

    spacing: Appearance.island.expanded.gap
    // Discover only while the adapter is on; this also starts it when Bluetooth is switched on here.
    Component.onCompleted: Bt.setDiscovering(Bt.enabled)
    Component.onDestruction: Bt.setDiscovering(false)

    Connections {
        function onEnabledChanged(): void {
            Bt.setDiscovering(Bt.enabled);
        }

        target: Bt
    }

    StyledText {
        Layout.fillWidth: true
        visible: !Bt.enabled
        text: Bt.available ? "Bluetooth is off" : "No Bluetooth adapter"
        color: Colors.surfaceVariantFg
    }

    ListView {
        Layout.fillWidth: true
        implicitHeight: Math.min(contentHeight, Appearance.island.expanded.listMaxHeight)
        visible: Bt.enabled
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: ScriptModel {
            values: [...root.devices]
        }

        delegate: ListRow {
            id: row

            required property BluetoothDevice modelData

            width: ListView.view.width
            icon: Icons.btDevice(row.modelData?.icon ?? "")
            title: row.modelData?.name ?? ""
            subtitle: row.modelData ? Bt.stateText(row.modelData) : ""
            active: row.modelData?.connected ?? false
            onActivated: root.choose(row.modelData)
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: Bt.enabled
        text: "Devices that ask for a PIN can't pair here; pair them once with bluetoothctl."
        wrapMode: Text.Wrap
        color: Colors.surfaceVariantFg
        font.pixelSize: Appearance.font.size.small
    }

    SettingsLink {
        label: "Bluetooth settings"
        page: "bluetooth"
    }
}
