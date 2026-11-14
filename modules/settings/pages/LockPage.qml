import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.containers
import qs.components.controls
import qs.modules.settings

SettingsPage {
    id: root

    // "Never", "45 s", "5 min"
    function span(seconds: int): string {
        if (seconds <= 0)
            return "Never";
        return seconds < 120 ? `${seconds} s` : `${Math.round(seconds / 60)} min`;
    }

    Group {
        Layout.fillWidth: true
        title: "When the computer is left alone"
        note: "Each step can be turned off by setting it to Never. Keep Awake holds all three back while it is on."

        ListRow {
            Layout.fillWidth: true
            title: "Lock the screen after"
            icon: "lock_clock"
            interactive: false

            Stepper {
                value: Config.idle.lockAfter
                from: 0
                to: 3600
                step: 60
                text: root.span(Config.idle.lockAfter)
                onMoved: value => Config.idle.lockAfter = value
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Turn the screens off after"
            icon: "bedtime"
            interactive: false

            Stepper {
                value: Config.idle.screenOffAfter
                from: 0
                to: 3600
                step: 60
                text: root.span(Config.idle.screenOffAfter)
                onMoved: value => Config.idle.screenOffAfter = value
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Suspend after"
            icon: "power_settings_new"
            interactive: false
            separator: false

            Stepper {
                value: Config.idle.suspendAfter
                from: 0
                to: 7200
                step: 300
                text: root.span(Config.idle.suspendAfter)
                onMoved: value => Config.idle.suspendAfter = value
            }
        }
    }

    Group {
        Layout.fillWidth: true
        title: "Locking"
        note: "The shell's own lock screen is used unless session.lockCommand in the settings file names another."

        ListRow {
            Layout.fillWidth: true
            title: "Lock before sleep"
            subtitle: "So the computer wakes up locked"
            icon: "lock"
            interactive: false

            Switch {
                checked: Config.idle.lockBeforeSleep
                onToggled: Config.idle.lockBeforeSleep = !Config.idle.lockBeforeSleep
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Lock when the system asks"
            subtitle: "For example, loginctl lock-session"
            icon: "terminal"
            interactive: false
            separator: false

            Switch {
                checked: Config.idle.lockOnRequest
                onToggled: Config.idle.lockOnRequest = !Config.idle.lockOnRequest
            }
        }
    }
}
