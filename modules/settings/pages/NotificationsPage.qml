import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.containers
import qs.components.controls
import qs.modules.settings

SettingsPage {
    Group {
        Layout.fillWidth: true
        title: "Notifications"
        note: "With Do Not Disturb on, notifications are still collected but not announced. Critical ones get through."

        ListRow {
            Layout.fillWidth: true
            title: "Do Not Disturb"
            icon: "notifications_off"
            interactive: false

            Switch {
                checked: ShellState.doNotDisturb
                onToggled: ShellState.doNotDisturb = !ShellState.doNotDisturb
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Announce for"
            icon: "timer"
            interactive: false

            Stepper {
                value: Config.notifications.bannerTimeout
                from: 1000
                to: 30000
                step: 1000
                text: `${Config.notifications.bannerTimeout / 1000} s`
                onMoved: value => Config.notifications.bannerTimeout = value
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Lines of text"
            subtitle: "Before a long notification is cut off"
            icon: "notes"
            interactive: false
            separator: false

            Stepper {
                value: Config.notifications.bodyLines
                from: 1
                to: 10
                onMoved: value => Config.notifications.bodyLines = value
            }
        }
    }

    Group {
        Layout.fillWidth: true
        title: "On-screen display"

        ListRow {
            Layout.fillWidth: true
            title: "Show volume, brightness and messages"
            icon: "volume_up"
            interactive: false

            Switch {
                checked: Config.osd.enabled
                onToggled: Config.osd.enabled = !Config.osd.enabled
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Levels stay for"
            icon: "timer"
            interactive: false

            Stepper {
                value: Config.osd.levelTimeout
                from: 500
                to: 10000
                step: 500
                text: `${Config.osd.levelTimeout / 1000} s`
                onMoved: value => Config.osd.levelTimeout = value
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Messages stay for"
            icon: "timer"
            interactive: false
            separator: false

            Stepper {
                value: Config.osd.toastTimeout
                from: 500
                to: 10000
                step: 500
                text: `${Config.osd.toastTimeout / 1000} s`
                onMoved: value => Config.osd.toastTimeout = value
            }
        }
    }
}
