pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.modules.island.dashboard.cards
import qs.services
import qs.themes

// System tab (frame 15): clock and weather on the left, six stat tiles on the right.
RowLayout {
    id: root

    // Bytes per GB as df and the frame show disk sizes, bytes per MB for network rates, and the
    // temperature that fills the bar (°C).
    readonly property real gb: 1e9
    readonly property real mb: 1e6
    readonly property real hotTemperature: 100
    readonly property string gpuIdle: SysInfo.gpuState === "sleeping" ? "Sleeping" : "—"
    readonly property string gpuLoad: `${Math.round(SysInfo.gpu * 100)}%`
    readonly property string gpuValue: SysInfo.gpuState === "active" ? root.gpuLoad : root.gpuIdle
    readonly property var tiles: [
        {
            icon: "memory",
            label: "CPU",
            value: `${Math.round(SysInfo.cpu * 100)}%`,
            level: SysInfo.cpu
        },
        {
            icon: "memory_alt",
            label: "RAM",
            value: `${Math.round(SysInfo.mem * 100)}%`,
            level: SysInfo.mem
        },
        {
            icon: "speed",
            label: "GPU",
            value: root.gpuValue,
            level: SysInfo.gpuState === "active" ? SysInfo.gpu : 0
        },
        {
            icon: "hard_drive",
            label: "Disk",
            value: `${Math.round(SysInfo.diskUsed / root.gb)} / ${Math.round(SysInfo.diskTotal / root.gb)} GB`,
            level: SysInfo.disk
        },
        {
            icon: "lan",
            label: "Network",
            value: `↓ ${(SysInfo.netDown / root.mb).toFixed(1)} ↑ ${(SysInfo.netUp / root.mb).toFixed(1)} MB/s`,
            level: 0
        },
        {
            icon: "thermostat",
            label: "Temp",
            value: SysInfo.temperature >= 0 ? `${SysInfo.temperature}°C` : "—",
            level: Math.max(0, SysInfo.temperature) / root.hotTemperature
        }
    ]

    readonly property list<real> shares: Appearance.island.dashboard.systemShares
    readonly property real freeWidth: root.width - Appearance.island.expanded.gap
    readonly property real clockWidth: root.freeWidth * root.shares[0] / (root.shares[0] + root.shares[1])

    spacing: Appearance.island.expanded.gap

    ClockCard {
        Layout.fillHeight: true
        Layout.preferredWidth: root.clockWidth
        showWeather: true
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 3
        rowSpacing: Appearance.island.expanded.gap
        columnSpacing: Appearance.island.expanded.gap

        Repeater {
            model: root.tiles

            Card {
                id: tile

                required property var modelData

                Layout.fillWidth: true
                Layout.preferredHeight: Appearance.island.dashboard.statTile
                icon: tile.modelData.icon
                title: tile.modelData.label

                StyledText {
                    text: tile.modelData.value
                    font.pixelSize: Appearance.font.size.large
                    font.weight: Font.DemiBold
                }

                LevelBar {
                    Layout.fillWidth: true
                    implicitHeight: Appearance.control.trackHeight
                    value: tile.modelData.level
                }
            }
        }
    }
}
