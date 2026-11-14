pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components.containers
import qs.components.controls
import qs.modules.settings

SettingsPage {
    id: root

    // "Automatic" first, then every connected monitor.
    readonly property list<string> monitors: ["", ...Quickshell.screens.map(screen => screen.name)]
    readonly property list<var> pulses: [
        {
            kind: "workspace",
            title: "Switching workspace"
        },
        {
            kind: "volume",
            title: "Volume changes"
        },
        {
            kind: "mic",
            title: "Microphone muted or unmuted"
        },
        {
            kind: "network",
            title: "Network connects or disconnects"
        },
        {
            kind: "battery",
            title: "Charger plugged or unplugged, low battery"
        },
        {
            kind: "media",
            title: "Track changes"
        },
        {
            kind: "notification",
            title: "Notifications arrive or go"
        }
    ]

    function setPulse(kind: string, on: bool): void {
        const kinds = Config.island.pulseOn.filter(k => k !== kind);
        if (on)
            kinds.push(kind);
        Config.island.pulseOn = kinds;
    }

    Group {
        Layout.fillWidth: true
        title: "Island"

        ListRow {
            Layout.fillWidth: true
            title: "Show the island"
            icon: "dock_to_bottom"
            interactive: false

            Switch {
                checked: Config.island.enabled
                onToggled: Config.island.enabled = !Config.island.enabled
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Monitor"
            subtitle: "Automatic uses the first monitor"
            icon: "monitor"
            interactive: false

            SegmentedControl {
                segments: root.monitors.map(name => name.length > 0 ? name : "Automatic")
                current: Math.max(0, root.monitors.indexOf(Config.island.monitor))
                onSelected: index => Config.island.monitor = root.monitors[index]
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Space below the island"
            subtitle: `Windows start ${Tokens.island.height + Config.island.reserveGap + Config.border.thickness} px down: ${Tokens.island.height} island + this + ${Config.border.thickness} border`
            icon: "vertical_align_top"
            interactive: false

            Stepper {
                value: Config.island.reserveGap
                from: 0
                to: 40
                step: 2
                text: `${Config.island.reserveGap} px`
                onMoved: value => Config.island.reserveGap = value
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Clock"
            icon: "schedule"
            interactive: false

            SegmentedControl {
                segments: ["24-hour", "12-hour"]
                current: Config.island.clockFormat === "hh:mm" ? 0 : 1
                onSelected: index => Config.island.clockFormat = index === 0 ? "hh:mm" : "h:mm AP"
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Notifications on hover"
            subtitle: "Whether the hovered island lists them when there are none"
            icon: "notifications"
            interactive: false

            SegmentedControl {
                readonly property var modes: ["always", "whenAny", "never"]

                segments: ["Always", "When any", "Never"]
                current: Math.max(0, modes.indexOf(Config.island.hoveredNotifications))
                onSelected: index => Config.island.hoveredNotifications = modes[index]
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Workspaces per page"
            subtitle: "Match the page size in your Hyprland binds"
            icon: "more_horiz"
            interactive: false
            separator: false

            Stepper {
                value: Config.island.workspaces
                from: 1
                to: 20
                onMoved: value => Config.island.workspaces = value
            }
        }
    }

    Group {
        Layout.fillWidth: true
        title: "Timing"

        ListRow {
            Layout.fillWidth: true
            title: "Shrink to the clock"
            subtitle: "Off keeps the island showing status all the time"
            icon: "pill"
            interactive: false

            Switch {
                checked: Config.island.idleView
                onToggled: Config.island.idleView = !Config.island.idleView
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Shrink after"
            subtitle: "How long the island shows status after something happens"
            icon: "timer"
            interactive: false
            disabled: !Config.island.idleView

            Stepper {
                value: Config.island.pulseDuration
                from: 1000
                to: 60000
                step: 1000
                disabled: !Config.island.idleView
                text: `${Config.island.pulseDuration / 1000} s`
                onMoved: value => Config.island.pulseDuration = value
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Open on hover after"
            icon: "mouse"
            interactive: false

            Stepper {
                value: Config.island.hoverEnterDelay
                from: 0
                to: 1000
                step: 20
                text: `${Config.island.hoverEnterDelay} ms`
                onMoved: value => Config.island.hoverEnterDelay = value
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Close after the pointer leaves for"
            icon: "mouse"
            interactive: false
            separator: false

            Stepper {
                value: Config.island.hoverExitDelay
                from: 0
                to: 2000
                step: 50
                text: `${Config.island.hoverExitDelay} ms`
                onMoved: value => Config.island.hoverExitDelay = value
            }
        }
    }

    Group {
        Layout.fillWidth: true
        title: "Show status when"

        Repeater {
            model: root.pulses

            ListRow {
                id: row

                required property var modelData
                required property int index

                Layout.fillWidth: true
                title: modelData.title
                interactive: false
                separator: index < root.pulses.length - 1

                Switch {
                    checked: Config.island.pulseOn.includes(row.modelData.kind)
                    onToggled: root.setPulse(row.modelData.kind, !checked)
                }
            }
        }
    }
}
