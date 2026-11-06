pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.themes
import qs.utils

// Power: battery and time left, power profile, then session actions. Log out, reboot and power off
// ask for a second click, so a stray click can't end the session.
ColumnLayout {
    id: root

    // The action waiting for its confirming click, "" when none.
    property string armed: ""
    readonly property var actions: [
        {
            name: "lock",
            icon: "lock",
            confirm: false
        },
        {
            name: "suspend",
            icon: "bedtime",
            confirm: false
        },
        {
            name: "logout",
            icon: "logout",
            confirm: true
        },
        {
            name: "reboot",
            icon: "restart_alt",
            confirm: true
        },
        {
            name: "poweroff",
            icon: "power_settings_new",
            confirm: true
        }
    ]

    function run(action: var): void {
        if (action.confirm && root.armed !== action.name) {
            root.armed = action.name;
            return;
        }
        root.armed = "";
        Session[action.name]();
    }

    function batteryState(): string {
        if (Battery.timeLeftText !== "")
            return Battery.timeLeftText;
        if (Battery.full)
            return "Fully charged";
        return Battery.charging ? "Charging" : "On battery";
    }

    spacing: Appearance.island.expanded.gap

    RowLayout {
        visible: Battery.available
        spacing: Appearance.island.expanded.gap

        MaterialIcon {
            text: Icons.battery(Battery.level, Battery.charging, Battery.low, Battery.full)
            size: Appearance.island.osd.icon
            color: Battery.charging ? Colors.success : Battery.low ? Colors.error : Colors.surfaceFg
        }

        StyledText {
            text: `${Math.round(Battery.level * 100)}%`
            font.pixelSize: Appearance.font.size.title
            font.weight: Font.DemiBold
        }

        StyledText {
            text: root.batteryState()
            color: Colors.surfaceVariantFg
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        Repeater {
            model: Battery.profiles

            StyledButton {
                required property string modelData

                Layout.fillWidth: true
                text: Battery.profileLabel(modelData)
                checked: Battery.profile === modelData
                enabled: modelData !== "performance" || Battery.hasPerformance
                onClicked: Battery.setProfile(modelData)
            }
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Appearance.spacing.normal

        Repeater {
            model: root.actions

            StyledButton {
                required property var modelData
                readonly property bool waiting: root.armed === modelData.name

                icon: modelData.icon
                text: waiting ? "Confirm" : ""
                filled: waiting
                onClicked: root.run(modelData)
            }
        }
    }

    SettingsLink {
        label: "Power settings"
        page: "power"
    }
}
