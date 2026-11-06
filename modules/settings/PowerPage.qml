pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services
import qs.themes

ColumnLayout {
    id: root

    // Labels and icons for power-profiles-daemon's profile names.
    readonly property var profileLabels: ({
            "power-saver": "Power saver",
            "balanced": "Balanced",
            "performance": "Performance"
        })
    readonly property var profileIcons: ({
            "power-saver": "eco",
            "balanced": "balance",
            "performance": "speed"
        })

    spacing: Appearance.settings.padding

    Section {
        title: "Power profile"

        RowLayout {
            spacing: Appearance.spacing.normal

            Repeater {
                model: Battery.profiles

                StyledButton {
                    required property string modelData

                    text: root.profileLabels[modelData]
                    icon: root.profileIcons[modelData]
                    checked: Battery.profile === modelData
                    enabled: modelData !== "performance" || Battery.hasPerformance
                    onClicked: Battery.setProfile(modelData)
                }
            }
        }
    }

    Section {
        title: "Idle"
        description: "Off by default so it doesn't double up with another idle manager such as hypridle."

        SettingRow {
            label: "Lock and turn the screen off when idle"

            StyledSwitch {
                checked: Config.idle.enabled
                onToggled: enabled => Config.idle.enabled = enabled
            }
        }

        SettingRow {
            label: "Lock after"
            sublabel: "Minutes"

            MinutesField {
                seconds: Config.idle.lockAfter
                onCommitted: seconds => Config.idle.lockAfter = seconds
            }
        }

        SettingRow {
            label: "Turn the screen off after"
            sublabel: "Minutes"

            MinutesField {
                seconds: Config.idle.screenOffAfter
                onCommitted: seconds => Config.idle.screenOffAfter = seconds
            }
        }
    }

    Section {
        title: "Battery"

        SettingRow {
            label: "Low battery warning"
            sublabel: "Percent; the island turns red at or below this"

            StyledTextField {
                implicitWidth: Appearance.control.numberWidth
                text: `${Math.round(Config.battery.lowLevel * 100)}`
                validator: IntValidator {
                    bottom: 1
                    top: 99
                }
                onEditingFinished: Config.battery.lowLevel = parseInt(text) / 100
            }
        }
    }

    component MinutesField: StyledTextField {
        id: field

        required property int seconds

        signal committed(int seconds)

        implicitWidth: Appearance.control.numberWidth
        text: `${Math.round(field.seconds / 60)}`
        validator: IntValidator {
            bottom: 1
            top: 1440
        }
        onEditingFinished: field.committed(parseInt(field.text) * 60)
    }
}
