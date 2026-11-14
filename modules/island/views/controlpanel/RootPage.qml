pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.island
import qs.modules.settings
import qs.modules.island.components

// The control panel's first page: a header with the time and session
// buttons, the toggles, then brightness and volume, each paired with the
// toggle that belongs to it.
PanelPage {
    id: root

    // How the record button can start; the config remembers which.
    readonly property list<var> recordModes: [
        {
            name: "screen",
            short: "Record",
            title: "Screen",
            subtitle: "The screen in use, without sound",
            icon: "desktop_windows"
        },
        {
            name: "sound",
            short: "Record + sound",
            title: "Screen with sound",
            subtitle: "What the computer is playing as well",
            icon: "volume_up"
        },
        {
            name: "region",
            short: "Record area",
            title: "Area",
            subtitle: "Choose a window or drag an area first",
            icon: "crop"
        }
    ]
    readonly property int recordMode: Math.max(0, recordModes.findIndex(mode => mode.name === Config.capture.recordMode))
    property bool choosingRecordMode

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.sm

        ColumnLayout {
            spacing: 0

            Clock {
                fontSize: Tokens.fontSize.xxl
            }

            Label {
                text: Time.format("dddd, MMMM d")
                level: Label.Secondary
            }
        }

        Item {
            Layout.fillWidth: true
        }

        RowLayout {
            visible: Battery.available
            spacing: Tokens.spacing.xxs

            Icon {
                name: Symbols.battery(Battery.level, Battery.pluggedIn)
                color: Battery.low ? Theme.color.red : Theme.color.label
            }

            Label {
                text: `${Math.round(Battery.level * 100)}%`
                tabular: true
            }
        }

        IconButton {
            icon: "settings"
            size: Tokens.size.xl
            onActivated: {
                SettingsState.open("");
                IslandState.close();
            }

            HoverHandler {
                id: settingsHover
            }

            Tooltip {
                text: "Settings"
                shown: settingsHover.hovered
            }
        }

        IconButton {
            icon: "power_settings_new"
            size: Tokens.size.xl
            // Lights up once the session sheet exists.
            disabled: !IslandState.knownViews.includes("session")
            onActivated: IslandState.open("session")

            HoverHandler {
                id: sessionHover
            }

            Tooltip {
                text: "Session"
                shown: sessionHover.hovered
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Tokens.spacing.sm
        rowSpacing: Tokens.spacing.sm
        uniformCellWidths: true

        ToggleTile {
            Layout.fillWidth: true
            icon: Network.wifiEnabled ? "wifi" : "wifi_off"
            title: "Wi-Fi"
            status: !Network.wifiEnabled ? "Off" : Network.wifiConnected ? Network.ssid : "Not connected"
            checked: Network.wifiEnabled
            hasPage: true
            onToggled: Network.setWifiEnabled(!Network.wifiEnabled)
            onOpened: IslandState.openPanel("wifi")
        }

        ToggleTile {
            Layout.fillWidth: true
            icon: Bluetooth.enabled ? "bluetooth" : "bluetooth_disabled"
            title: "Bluetooth"
            status: !Bluetooth.available ? "Unavailable" : !Bluetooth.enabled ? "Off" : Bluetooth.connected.length > 0 ? Bluetooth.connected[0].name : "On"
            checked: Bluetooth.enabled
            hasPage: true
            disabled: !Bluetooth.available
            onToggled: Bluetooth.setEnabled(!Bluetooth.enabled)
            onOpened: IslandState.openPanel("bluetooth")
        }

        ToggleTile {
            Layout.fillWidth: true
            icon: "coffee"
            title: "Keep Awake"
            status: KeepAwake.enabled ? "On" : "Off"
            checked: KeepAwake.enabled
            onToggled: KeepAwake.toggle()
        }

        ToggleTile {
            Layout.fillWidth: true
            icon: ShellState.doNotDisturb ? "notifications_off" : "notifications"
            title: "Do Not Disturb"
            status: ShellState.doNotDisturb ? "On" : "Off"
            checked: ShellState.doNotDisturb
            onToggled: ShellState.doNotDisturb = !ShellState.doNotDisturb
        }
    }

    // Brightness, with night light beside it.
    RowLayout {
        Layout.fillWidth: true
        visible: Brightness.available
        spacing: Tokens.spacing.sm

        LevelSlider {
            Layout.fillWidth: true
            size: Tokens.size.xxl
            icon: Symbols.level("brightness", Brightness.value)
            value: Brightness.value
            onMoved: value => Brightness.set(value)
        }

        ToggleButton {
            icon: "bedtime"
            size: Tokens.size.xxl
            checked: NightLight.enabled
            onActivated: NightLight.setEnabled(!NightLight.enabled)
            onSecondaryActivated: IslandState.openPanel("nightlight")

            HoverHandler {
                id: nightHover
            }
        }
    }

    // Volume, with the microphone beside it.
    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.sm

        LevelSlider {
            Layout.fillWidth: true
            size: Tokens.size.xxl
            icon: Audio.muted ? "volume_off" : Symbols.level("speaker", Audio.volume)
            value: Audio.volume
            tint: Audio.muted ? Theme.color.grey : Theme.accent
            onMoved: value => Audio.setVolume(value)
        }

        ToggleButton {
            icon: Audio.micMuted ? "mic_off" : "mic"
            size: Tokens.size.xxl
            // Lit while the microphone is live.
            checked: !Audio.micMuted
            onActivated: Audio.toggleMicMute()
            onSecondaryActivated: IslandState.openPanel("audio")

            HoverHandler {
                id: micHover
            }
        }
    }

    // Capture: a screenshot, and recording with a choice of how.
    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.sm

        Button {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            text: "Screenshot"
            icon: "screenshot_region"
            size: Tokens.size.xxl
            capsule: true
            onActivated: {
                IslandState.close();
                Capture.screenshotSoon("");
            }
        }

        SplitButton {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            text: Capture.recording ? `Stop ${Capture.clock(Capture.elapsed)}` : root.recordModes[root.recordMode].short
            icon: Capture.recording ? "stop_circle" : "videocam"
            size: Tokens.size.xxl
            style: Capture.recording ? Button.Filled : Button.Gray
            role: Capture.recording ? Button.Destructive : Button.Normal
            expanded: root.choosingRecordMode
            onMenuActivated: root.choosingRecordMode = !root.choosingRecordMode
            onActivated: {
                if (Capture.recording) {
                    Capture.stop();
                } else {
                    IslandState.close();
                    Capture.recordSoon("");
                }
            }
        }
    }

    Reveal {
        Layout.fillWidth: true
        shown: root.choosingRecordMode
        collapse: Reveal.Vertical

        OptionList {
            options: root.recordModes
            current: root.recordMode
            onSelected: index => {
                Config.capture.recordMode = root.recordModes[index].name;
                root.choosingRecordMode = false;
            }
        }
    }

    // Notifications: how many, with the way in to the full list.
    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.sm

        Icon {
            name: ShellState.doNotDisturb ? "notifications_off" : "notifications"
            level: Icon.Secondary
        }

        Label {
            Layout.fillWidth: true
            text: Notifications.count === 0 ? "No notifications" : Notifications.count === 1 ? "1 notification" : `${Notifications.count} notifications`
            level: Label.Secondary
        }

        Button {
            text: "Clear"
            style: Button.Plain
            visible: Notifications.count > 0
            onActivated: Notifications.clear()
        }

        Button {
            text: "Show all"
            capsule: true
            onActivated: IslandState.open("notifications")
        }
    }
}
