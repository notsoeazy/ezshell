pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.modules.island.dashboard.cards
import qs.services
import qs.state
import qs.themes
import qs.utils

// The E2 quick toggles, icon-only in the bento (frame 14), with the notifications summary under them.
// Tiles keep the tile rule: left click toggles, right click opens the detail section.
Card {
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

    // "Discord, Firefox": the apps behind the unread notifications, newest first, without repeats.
    function senders(): string {
        const apps = [...Notifs.list].reverse().map(n => n.appName).filter(a => a !== "");
        return [...new Set(apps)].join(", ");
    }

    icon: "tune"
    title: "Quick toggles"

    GridLayout {
        Layout.fillWidth: true
        columns: 3
        rowSpacing: Appearance.spacing.normal
        columnSpacing: Appearance.spacing.normal

        Tile {
            Layout.fillWidth: true
            compact: true
            icon: Icons.wifi(Wifi.enabled, Wifi.connected, Wifi.strength)
            label: "Wi‑Fi"
            status: root.wifiStatus()
            active: Wifi.enabled
            onToggled: Wifi.toggle()
            onOpened: root.open("wifi")
        }

        Tile {
            Layout.fillWidth: true
            compact: true
            icon: Icons.bluetooth(Bt.enabled, Bt.connected.length > 0)
            label: "Bluetooth"
            status: Bt.enabled ? (Bt.connectedName !== "" ? Bt.connectedName : "On") : "Off"
            active: Bt.enabled
            onToggled: Bt.toggle()
            onOpened: root.open("bluetooth")
        }

        Tile {
            Layout.fillWidth: true
            compact: true
            icon: "nightlight"
            label: "Night light"
            status: NightLight.enabled ? `${NightLight.temperature} K` : "Off"
            active: NightLight.enabled
            hasDetail: false
            onToggled: NightLight.toggle()
        }

        Tile {
            Layout.fillWidth: true
            compact: true
            icon: "do_not_disturb_on"
            label: "Do not disturb"
            status: Notifs.dnd ? "On" : "Off"
            active: Notifs.dnd
            hasDetail: false
            onToggled: Notifs.toggleDnd()
        }

        Tile {
            Layout.fillWidth: true
            compact: true
            icon: Audio.micMuted ? "mic_off" : "mic"
            label: "Microphone"
            status: Audio.micMuted ? "Muted" : "On"
            active: !Audio.micMuted
            onToggled: Audio.toggleMicMute()
            onOpened: root.open("audio")
        }

        Tile {
            Layout.fillWidth: true
            compact: true
            icon: "bolt"
            label: "Power"
            status: Battery.profileLabel(Battery.profile)
            toggleable: false
            onOpened: root.open("power")
        }
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: Appearance.control.borderWidth
        color: Colors.outlineVariant
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.island.expanded.gap

        StyledRect {
            implicitWidth: Appearance.island.expanded.iconBox
            implicitHeight: Appearance.island.expanded.iconBox
            radius: height / 2
            color: Colors.tertiaryContainer

            MaterialIcon {
                anchors.centerIn: parent
                text: Notifs.dnd ? "notifications_off" : "notifications"
                color: Colors.tertiaryContainerFg
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: Notifs.count > 0 ? `${Notifs.count} new` : "No notifications"
                font.weight: Font.Medium
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.senders()
                elide: Text.ElideRight
                color: Colors.surfaceVariantFg
                font.pixelSize: Appearance.font.size.small
            }
        }

        MaterialIcon {
            text: "chevron_right"
            color: Colors.surfaceVariantFg
        }

        TapHandler {
            onTapped: Visibility.push("notifications")
        }
    }
}
