pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.state
import qs.themes

// Expanded-island header. On a tab: the tab row with battery % and a power button. On a detail section
// or sub-page: a back chevron, the title and the page's main switch (docs/ISLAND.md).
Item {
    id: root

    required property string screenName
    required property string section
    required property string page
    required property bool onTab
    readonly property var titles: ({
            "control": "Control",
            "weather": "Weather",
            "media": "Media",
            "system": "System",
            "calendar": "Calendar",
            "wifi": "Wi‑Fi",
            "bluetooth": "Bluetooth",
            "audio": "Audio",
            "power": "Power",
            "display": "Display",
            "wallpapers": "Wallpapers",
            "capture": "Capture",
            "keybinds": "Keybinds"
        })
    // A detail page's main switch, on the right of its header.
    readonly property var switches: ({
            "wifi": wifiSwitch,
            "bluetooth": bluetoothSwitch,
            "display": displaySwitch
        })

    implicitHeight: Appearance.island.expanded.header

    RowLayout {
        id: tabRow

        anchors.fill: parent
        visible: root.onTab
        spacing: Appearance.island.expanded.tabGap

        Repeater {
            id: tabs

            model: Visibility.tabs

            StyledText {
                id: tab

                required property string modelData
                readonly property bool active: tab.modelData === root.section

                text: root.titles[tab.modelData]
                color: tab.active ? Colors.primary : Colors.surfaceVariantFg
                font.weight: tab.active ? Font.DemiBold : Font.Medium

                TapHandler {
                    margin: Appearance.spacing.small
                    onTapped: Visibility.openByPointer(tab.modelData, root.screenName)
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        StyledText {
            visible: Battery.available
            text: `${Math.round(Battery.level * 100)}%`
            color: Colors.surfaceVariantFg
        }

        MaterialIcon {
            text: "power_settings_new"

            TapHandler {
                margin: Appearance.spacing.small
                onTapped: Visibility.openByPointer("power", root.screenName)
            }
        }
    }

    // One underline for all tabs: it slides and stretches to the active tab instead of jumping.
    StyledRect {
        id: underline

        // itemAt() doesn't notify when the Repeater creates its items; depending on count re-evaluates it.
        readonly property Item activeTab: tabs.count > 0 ? tabs.itemAt(Visibility.tabs.indexOf(root.section)) : null

        visible: root.onTab && underline.activeTab !== null
        x: tabRow.x + (underline.activeTab?.x ?? 0)
        y: (underline.activeTab?.y ?? 0) + (underline.activeTab?.height ?? 0) + Appearance.spacing.small
        width: underline.activeTab?.width ?? 0
        height: Appearance.island.expanded.tabIndicator
        radius: height / 2
        color: Colors.primary

        Behavior on x {
            Anim {}
        }

        Behavior on width {
            Anim {}
        }
    }

    RowLayout {
        anchors.fill: parent
        visible: !root.onTab
        spacing: Appearance.spacing.normal

        MaterialIcon {
            text: "arrow_back"

            TapHandler {
                margin: Appearance.spacing.small
                onTapped: Visibility.back()
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: root.titles[root.page] ?? ""
            font.pixelSize: Appearance.font.size.large
            font.weight: Font.DemiBold
        }

        Loader {
            sourceComponent: root.switches[root.page] ?? null
        }
    }

    Component {
        id: wifiSwitch

        StyledSwitch {
            checked: Wifi.enabled
            onToggled: enabled => Wifi.setEnabled(enabled)
        }
    }

    Component {
        id: bluetoothSwitch

        StyledSwitch {
            enabled: Bt.available
            checked: Bt.enabled
            onToggled: enabled => Bt.setEnabled(enabled)
        }
    }

    Component {
        id: displaySwitch

        StyledSwitch {
            checked: NightLight.enabled
            onToggled: enabled => NightLight.set(enabled)
        }
    }
}
