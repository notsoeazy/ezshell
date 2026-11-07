pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services
import qs.themes
import qs.utils

// Display (from the Control tab's Display chevron): brightness, night light and its warmth, and the
// night light schedule (F8).
ColumnLayout {
    id: root

    // hyprsunset's useful range; the slider runs warm (left) to neutral (right).
    readonly property int warmest: 1000
    readonly property int neutral: 6500
    readonly property var schedules: [["off", "Off"], ["fixed", root.fixedLabel], ["sun", "Sunset to sunrise"]]
    readonly property string fixedLabel: `${Config.nightLight.start}–${Config.nightLight.end}`

    function kelvinAt(value: real): int {
        return Math.round(root.warmest + value * (root.neutral - root.warmest));
    }

    spacing: Appearance.island.expanded.gap

    component Heading: StyledText {
        color: Colors.surfaceVariantFg
        font.pixelSize: Appearance.font.size.small
        font.weight: Font.Medium
    }

    component Row: RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal
    }

    Heading {
        visible: Brightness.available
        text: "Brightness"
    }

    Row {
        visible: Brightness.available

        MaterialIcon {
            text: Icons.brightness(Brightness.level)
        }

        StyledSlider {
            Layout.fillWidth: true
            value: Brightness.level
            onMoved: value => Brightness.set(value)
        }

        StyledText {
            text: `${Math.round(Brightness.level * 100)}%`
            color: Colors.surfaceVariantFg
        }
    }

    Heading {
        text: "Night light"
    }

    Row {
        MaterialIcon {
            text: "nightlight"
            fill: NightLight.enabled ? 1 : 0
        }

        StyledText {
            Layout.fillWidth: true
            text: NightLight.enabled ? `On, ${NightLight.temperature} K` : "Off"
        }

        StyledSwitch {
            checked: NightLight.enabled
            onToggled: checked => NightLight.set(checked)
        }
    }

    Row {
        MaterialIcon {
            text: "thermostat"
            color: Colors.surfaceVariantFg
        }

        StyledSlider {
            Layout.fillWidth: true
            value: (NightLight.temperature - root.warmest) / (root.neutral - root.warmest)
            onMoved: value => NightLight.setTemperature(root.kelvinAt(value))
        }

        StyledText {
            text: `${NightLight.temperature} K`
            color: Colors.surfaceVariantFg
        }
    }

    Heading {
        text: "Schedule"
    }

    Row {
        Repeater {
            model: root.schedules

            StyledButton {
                required property var modelData

                text: modelData[1]
                checked: NightLight.schedule === modelData[0]
                onClicked: NightLight.setSchedule(modelData[0])
            }
        }
    }

    SettingsLink {
        page: "display"
        label: "Display settings"
    }
}
