pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services
import qs.themes

// Display and night light settings.
ColumnLayout {
    id: root

    readonly property int warmest: 1000
    readonly property int neutral: 6500

    function kelvinAt(value: real): int {
        return Math.round(root.warmest + value * (root.neutral - root.warmest));
    }

    function nextChangeText(): string {
        if (NightLight.schedule === "off")
            return "Off: only manual changes";
        const next = NightLight.nextChange;
        if (!next)
            return NightLight.schedule === "sun" ? "Waiting for the weather location" : "Check the times";
        return `Next change at ${Qt.formatTime(next, "HH:mm")}${NightLight.enabled ? " (off)" : " (on)"}`;
    }

    spacing: Appearance.settings.padding

    Section {
        visible: Brightness.available
        title: "Brightness"
        description: "Internal panel backlight."

        SettingRow {
            label: "Brightness"
            sublabel: `${Math.round(Brightness.level * 100)}%`

            StyledSlider {
                value: Brightness.level
                onMoved: value => Brightness.set(value)
            }
        }
    }

    Section {
        title: "Night light"
        description: "Warms the screen through hyprsunset. A manual change holds until the next scheduled one."

        SettingRow {
            label: "Night light"
            sublabel: NightLight.enabled ? `On, ${NightLight.temperature} K` : "Off"

            StyledSwitch {
                checked: NightLight.enabled
                onToggled: checked => NightLight.set(checked)
            }
        }

        SettingRow {
            label: "Warmth"
            sublabel: `${NightLight.temperature} K`

            StyledSlider {
                value: (NightLight.temperature - root.warmest) / (root.neutral - root.warmest)
                onMoved: value => NightLight.setTemperature(root.kelvinAt(value))
            }
        }

        SettingRow {
            label: "Schedule"
            sublabel: root.nextChangeText()

            Repeater {
                model: [["off", "Off"], ["fixed", "Fixed times"], ["sun", "Sunset to sunrise"]]

                StyledButton {
                    required property var modelData

                    text: modelData[1]
                    checked: NightLight.schedule === modelData[0]
                    onClicked: NightLight.setSchedule(modelData[0])
                }
            }
        }

        SettingRow {
            visible: NightLight.schedule === "fixed"
            label: "From and to"
            sublabel: "24-hour, e.g. 20:00 and 07:00"

            StyledTextField {
                id: start

                implicitWidth: Appearance.control.numberWidth
                text: Config.nightLight.start
                placeholder: "20:00"
                onEditingFinished: NightLight.setTimes(start.text, end.text)
            }

            StyledTextField {
                id: end

                implicitWidth: Appearance.control.numberWidth
                text: Config.nightLight.end
                placeholder: "07:00"
                onEditingFinished: NightLight.setTimes(start.text, end.text)
            }
        }
    }
}
