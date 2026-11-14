pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.settings

SettingsPage {
    Group {
        Layout.fillWidth: true
        title: "Brightness"
        note: Brightness.available ? "" : "No backlight was found, so brightness cannot be set here."

        LevelRow {
            Layout.fillWidth: true
            title: "Brightness"
            icon: "brightness_medium"
            separator: false
            disabled: !Brightness.available
            value: Brightness.value
            onMoved: value => Brightness.set(value)
        }
    }

    Group {
        Layout.fillWidth: true
        title: "Night Light"
        note: "Warmer colours are easier on the eyes at night. A lower temperature is warmer."

        ListRow {
            Layout.fillWidth: true
            title: "Night Light"
            icon: "nightlight"
            interactive: false

            Switch {
                checked: NightLight.enabled
                onToggled: NightLight.setEnabled(!NightLight.enabled)
            }
        }

        LevelRow {
            Layout.fillWidth: true
            title: "Colour temperature"
            icon: "thermostat"
            separator: false
            from: NightLight.warmest
            to: NightLight.coolest
            step: 100
            value: NightLight.temperature
            text: `${NightLight.temperature} K`
            onMoved: value => NightLight.setTemperature(value)
        }
    }

    Group {
        Layout.fillWidth: true
        title: "Sleep"
        note: "Stays on until you turn it off or the shell restarts."

        ListRow {
            Layout.fillWidth: true
            title: "Keep awake"
            subtitle: "Stop the screen from dimming, locking or sleeping"
            icon: "coffee"
            interactive: false
            separator: false

            Switch {
                checked: KeepAwake.enabled
                onToggled: KeepAwake.toggle()
            }
        }
    }

    Group {
        Layout.fillWidth: true
        title: "Monitors"
        note: "Resolution, refresh rate and scale are set in the Hyprland config."

        Repeater {
            model: Hypr.monitors

            ValueRow {
                required property HyprlandMonitor modelData
                required property int index

                Layout.fillWidth: true
                title: modelData.name
                subtitle: modelData.description
                icon: "monitor"
                separator: index < Hypr.monitors.length - 1
                value: Hypr.monitorMode(modelData)
            }
        }
    }
}
