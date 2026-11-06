pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.themes

ColumnLayout {
    id: root

    spacing: Appearance.settings.padding
    Component.onCompleted: Wifi.refreshSaved()

    Section {
        title: "Saved networks"
        description: "All saved profiles, in range or not. Duplicates of one name are listed separately."

        Repeater {
            model: Wifi.saved

            SettingRow {
                id: network

                required property var modelData

                icon: "wifi"
                label: network.modelData.name
                sublabel: network.modelData.name === Wifi.ssid ? "Connected" : ""

                StyledButton {
                    text: "Forget"
                    icon: "delete"
                    onClicked: Wifi.forgetSaved(network.modelData.uuid)
                }
            }
        }

        StyledText {
            visible: Wifi.saved.length === 0
            text: "No saved networks"
            color: Colors.surfaceVariantFg
        }
    }

    Section {
        title: "Hidden network"
        description: "For networks that don't broadcast their name. Replaces your current connection."

        SettingRow {
            label: "Network name"

            StyledTextField {
                id: ssid

                placeholder: "SSID"
            }
        }

        SettingRow {
            label: "Password"
            sublabel: "Leave empty for an open network"

            StyledTextField {
                id: password

                password: true
                placeholder: "Password"
            }
        }

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                text: Wifi.lastError
                color: Colors.error
            }

            StyledButton {
                text: "Connect"
                icon: "wifi_find"
                filled: true
                enabled: ssid.text !== ""
                onClicked: {
                    Wifi.connectHidden(ssid.text, password.text);
                    password.text = "";
                }
            }
        }
    }
}
