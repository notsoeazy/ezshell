pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.modules.island.dashboard.cards
import qs.services
import qs.themes

// Overview system card (frame 14): CPU, RAM, temperature and battery as labelled bars.
Card {
    id: root

    // Bytes per GiB, and the temperature that fills the bar (°C).
    readonly property real gib: 1073741824
    readonly property real hotTemperature: 100
    readonly property var rows: [
        {
            icon: "memory",
            label: "CPU",
            value: `${Math.round(SysInfo.cpu * 100)}%`,
            level: SysInfo.cpu
        },
        {
            icon: "memory_alt",
            label: "RAM",
            value: `${(SysInfo.memUsed / root.gib).toFixed(1)} / ${Math.round(SysInfo.memTotal / root.gib)} GB`,
            level: SysInfo.mem
        },
        {
            icon: "thermostat",
            label: "Temp",
            value: SysInfo.temperature >= 0 ? `${SysInfo.temperature}°C` : "—",
            level: Math.max(0, SysInfo.temperature) / root.hotTemperature
        },
        {
            icon: "battery_full",
            label: "Battery",
            value: [`${Math.round(Battery.level * 100)}%`, Battery.timeLeftText].filter(s => s !== "").join(" · "),
            level: Battery.level
        }
    ]

    icon: "monitoring"
    title: "System"

    Repeater {
        model: root.rows

        ColumnLayout {
            id: row

            required property var modelData

            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            RowLayout {
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    text: row.modelData.icon
                    size: Appearance.island.dashboard.headerIcon
                    color: Colors.surfaceVariantFg
                }

                StyledText {
                    Layout.fillWidth: true
                    text: row.modelData.label
                }

                StyledText {
                    text: row.modelData.value
                    font.weight: Font.DemiBold
                }
            }

            LevelBar {
                Layout.fillWidth: true
                implicitHeight: Appearance.control.trackHeight
                value: row.modelData.level
            }
        }
    }
}
