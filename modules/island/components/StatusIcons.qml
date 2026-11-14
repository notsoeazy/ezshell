import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.components
import qs.components.controls
import qs.services
import qs.utils

// System status at a glance: notifications with their count (only if there
// are any, or Do Not Disturb is on), microphone, volume, network, and battery
// (only if there is one).
RowLayout {
    id: root

    // Whether the notification count and bell are part of the row. Off where
    // the notifications have a place of their own; Do Not Disturb stays.

    spacing: Tokens.spacing.xs

    // The count sits left of the bell, so the bell stays against the icons
    // beside it whether or not there is a count.
    Reveal {
        shown: Notifications.count > 0
        collapse: Reveal.Horizontal
        fromScale: 0.6

        Badge {
            count: Notifications.count
        }
    }

    // The bell, crossed out under Do Not Disturb, which shows it even with
    // nothing waiting, and where the count and bell are left out.
    Reveal {
        shown: ShellState.doNotDisturb
        collapse: Reveal.Horizontal
        fromScale: 0.6

        Icon {
            name: "notifications_off"
            size: Tokens.icon.sm
            filled: true
        }
    }

    // White while on and unused, orange while an application records from it,
    // red while muted.
    Icon {
        name: Audio.micMuted ? "mic_off" : "mic"
        color: Audio.micMuted ? Theme.color.red : Audio.micInUse ? Theme.color.warning : Theme.color.label
        size: Tokens.icon.sm
        filled: true
    }

    Icon {
        name: Audio.muted ? "volume_off" : "volume_up"
        level: Audio.muted ? Icon.Secondary : Icon.Primary
        size: Tokens.icon.sm
        filled: true
    }

    Icon {
        name: Network.wiredConnected ? "lan" : Network.wifiEnabled ? "wifi" : "wifi_off"
        level: Network.connected ? Icon.Primary : Icon.Secondary
        size: Tokens.icon.sm
        filled: true
    }

    Icon {
        visible: Battery.available
        name: Symbols.battery(Battery.level, Battery.pluggedIn)
        color: Battery.low ? Theme.color.red : Theme.color.label
        size: Tokens.icon.sm
        filled: true
    }
}
