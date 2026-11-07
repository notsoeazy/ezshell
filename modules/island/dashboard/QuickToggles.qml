pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.state
import qs.themes
import qs.utils

// Control tab tiles (docs/ISLAND-R1.md): two columns of pill tiles and a column of round buttons.
GridLayout {
    id: root

    required property string screenName

    function wifiStatus(): string {
        if (!Wifi.enabled)
            return "Off";
        if (!Wifi.connected)
            return "Not connected";
        return Wifi.ssid !== "" ? Wifi.ssid : "Connected";
    }

    function open(section: string): void {
        Visibility.openByPointer(section, root.screenName);
    }

    columns: 3
    rowSpacing: Appearance.island.control.gap
    columnSpacing: Appearance.island.control.gap

    // A 44 px round button, filled primary while its state is on.
    component Round: StyledRect {
        id: round

        property string icon: ""
        property bool active: false

        signal clicked

        implicitWidth: Appearance.island.control.round
        implicitHeight: Appearance.island.control.round
        radius: height / 2
        color: round.active ? Colors.primary : Colors.surfaceContainerHigh

        Behavior on color {
            CAnim {}
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: round.icon
            fill: round.active ? 1 : 0
            color: round.active ? Colors.primaryFg : Colors.surfaceFg
        }

        TapHandler {
            onTapped: round.clicked()
        }
    }

    Tile {
        Layout.fillWidth: true
        icon: Icons.wifi(Wifi.enabled, Wifi.connected, Wifi.strength)
        label: "Wi‑Fi"
        status: root.wifiStatus()
        active: Wifi.enabled
        onToggled: Wifi.toggle()
        onOpened: root.open("wifi")
    }

    Tile {
        Layout.fillWidth: true
        icon: "do_not_disturb_on"
        label: "Focus"
        status: Notifs.dnd ? "Do not disturb" : "Off"
        active: Notifs.dnd
        hasDetail: false
        onToggled: Notifs.toggleDnd()
    }

    Round {
        icon: "lock"
        onClicked: {
            Visibility.close();
            Session.lock();
        }
    }

    Tile {
        Layout.fillWidth: true
        icon: Icons.bluetooth(Bt.enabled, Bt.connected.length > 0)
        label: "Bluetooth"
        status: Bt.enabled ? (Bt.connectedName !== "" ? Bt.connectedName : "On") : "Off"
        active: Bt.enabled
        onToggled: Bt.toggle()
        onOpened: root.open("bluetooth")
    }

    Tile {
        Layout.fillWidth: true
        icon: "nightlight"
        label: "Night light"
        status: NightLight.enabled ? `${NightLight.temperature} K` : "Off"
        active: NightLight.enabled
        onToggled: NightLight.toggle()
        onOpened: root.open("display")
    }

    Round {
        icon: "settings"
        onClicked: Visibility.open("settings", "")
    }

    Tile {
        Layout.fillWidth: true
        icon: "sports_esports"
        label: "Game mode"
        status: GameMode.active ? "On" : "Off"
        active: GameMode.active
        hasDetail: false
        onToggled: GameMode.toggle()
    }

    Tile {
        Layout.fillWidth: true
        icon: "coffee"
        label: "Keep awake"
        status: Idle.inhibited ? "On" : "Off"
        active: Idle.inhibited
        hasDetail: false
        onToggled: Idle.toggleInhibit()
    }

    Round {
        icon: Audio.micMuted ? "mic_off" : "mic"
        active: Audio.micMuted
        onClicked: Audio.toggleMicMute()
    }
}
