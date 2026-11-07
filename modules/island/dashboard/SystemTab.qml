pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.modules.island.dashboard.cards
import qs.services
import qs.themes

// System tab (docs/ISLAND-R1.md): a system monitor in two columns of cards, hyprism desktop-widget style.
// SysInfo samples only while this tab is open (Expanded.qml).
Flickable {
    id: root

    // Bytes per GB as df shows disk sizes.
    readonly property real gb: 1e9

    // 1234567 B/s → "1.2 MB/s"
    function rate(bytes: real): string {
        if (bytes >= 1e6)
            return `${(bytes / 1e6).toFixed(1)} MB/s`;
        return bytes >= 1e3 ? `${Math.round(bytes / 1e3)} KB/s` : `${Math.round(bytes)} B/s`;
    }

    // "165 / 316 GB"
    function sizes(used: real, size: real): string {
        return `${Math.round(used / root.gb)} / ${Math.round(size / root.gb)} GB`;
    }

    // 93784 s → "1d 2h 3m"
    function duration(seconds: real): string {
        const days = Math.floor(seconds / 86400);
        const hours = Math.floor(seconds % 86400 / 3600);
        const minutes = Math.floor(seconds % 3600 / 60);
        const parts = [days > 0 ? `${days}d` : "", hours > 0 ? `${hours}h` : "", `${minutes}m`];
        return parts.filter(p => p !== "").join(" ");
    }

    implicitHeight: Math.min(grid.implicitHeight, Appearance.island.expanded.pageMaxHeight)
    contentHeight: grid.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    // A value line: label on the left, value on the right.
    component Stat: RowLayout {
        id: stat

        required property string label
        required property string value

        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: stat.label
            color: Colors.surfaceVariantFg
        }

        StyledText {
            text: stat.value
            font.weight: Font.DemiBold
        }
    }

    GridLayout {
        id: grid

        width: root.width
        columns: 2
        rowSpacing: Appearance.island.control.gap
        columnSpacing: Appearance.island.control.gap

        Card {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            icon: "monitoring"
            title: "Performance"

            Stat {
                label: "CPU"
                value: `${Math.round(SysInfo.cpu * 100)}%`
            }

            Sparkline {
                Layout.fillWidth: true
                values: SysInfo.cpuHistory
            }

            Stat {
                label: "RAM"
                value: `${(SysInfo.memUsed / root.gb).toFixed(1)} / ${(SysInfo.memTotal / root.gb).toFixed(0)} GB`
            }

            Sparkline {
                Layout.fillWidth: true
                values: SysInfo.memHistory
                color: Colors.tertiary
            }
        }

        Card {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            icon: "lan"
            title: Wifi.ssid !== "" ? `Network · ${Wifi.ssid}` : "Network"

            Stat {
                label: "Download"
                value: root.rate(SysInfo.netDown)
            }

            Sparkline {
                Layout.fillWidth: true
                values: SysInfo.downHistory
                max: 0
            }

            Stat {
                label: "Upload"
                value: root.rate(SysInfo.netUp)
            }

            Sparkline {
                Layout.fillWidth: true
                values: SysInfo.upHistory
                max: 0
                color: Colors.tertiary
            }
        }

        Card {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            icon: "hard_drive"
            title: "Storage"

            Repeater {
                model: SysInfo.disks

                ColumnLayout {
                    id: disk

                    required property var modelData

                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    Stat {
                        label: disk.modelData.mount
                        value: root.sizes(disk.modelData.used, disk.modelData.size)
                    }

                    LevelBar {
                        Layout.fillWidth: true
                        implicitHeight: Appearance.control.trackHeight
                        value: disk.modelData.size > 0 ? disk.modelData.used / disk.modelData.size : 0
                    }
                }
            }
        }

        Card {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            icon: "thermostat"
            title: "Sensors"

            Repeater {
                model: SysInfo.sensors

                Stat {
                    required property var modelData

                    label: modelData.label
                    value: `${modelData.celsius}°C`
                }
            }

            Stat {
                visible: SysInfo.gpuState === "sleeping"
                label: "GPU"
                value: "Sleeping"
            }
        }

        Card {
            Layout.fillWidth: true
            Layout.columnSpan: 2
            icon: "info"
            title: "System"

            Stat {
                label: "Kernel"
                value: SysInfo.kernel
            }

            Stat {
                label: "Uptime"
                value: root.duration(SysInfo.uptime)
            }

            Stat {
                label: "Session"
                value: SysInfo.session
            }
        }
    }
}
