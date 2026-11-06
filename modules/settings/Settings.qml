pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.state
import qs.themes

// The settings app: an ordinary floating window, open while Visibility.settingsPage is set.
// Open it with `panels toggle settings` or `panels open settings <page>`.
Scope {
    id: root

    // Raw page table: name (used by IPC), sidebar label and icon.
    readonly property list<var> pages: [
        {
            name: "wifi",
            label: "Wi‑Fi",
            icon: "wifi"
        },
        {
            name: "bluetooth",
            label: "Bluetooth",
            icon: "bluetooth"
        },
        {
            name: "audio",
            label: "Audio",
            icon: "volume_up"
        },
        {
            name: "power",
            label: "Power",
            icon: "battery_full"
        },
        {
            name: "workspaces",
            label: "Workspaces",
            icon: "space_dashboard"
        },
        {
            name: "appearance",
            label: "Appearance",
            icon: "palette"
        }
    ]
    // Unknown page names fall back to the first page.
    readonly property bool known: root.pages.some(p => p.name === Visibility.settingsPage)
    readonly property string page: root.known ? Visibility.settingsPage : root.pages[0].name

    function componentFor(page: string): Component {
        switch (page) {
        case "bluetooth":
            return bluetoothPage;
        case "audio":
            return audioPage;
        case "power":
            return powerPage;
        case "workspaces":
            return workspacesPage;
        case "appearance":
            return appearancePage;
        default:
            return wifiPage;
        }
    }

    LazyLoader {
        active: Visibility.settingsPage !== ""

        FloatingWindow {
            title: "ezshell settings"
            implicitWidth: Appearance.settings.width
            implicitHeight: Appearance.settings.height
            color: Colors.surface
            onClosed: Visibility.closeSettings()

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Sidebar {
                    Layout.fillHeight: true
                    pages: root.pages
                    current: root.page
                    onSelected: name => Visibility.open("settings", name)
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: pageLoader.implicitHeight + 2 * Appearance.settings.padding
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Loader {
                        id: pageLoader

                        x: Appearance.settings.padding
                        y: Appearance.settings.padding
                        width: parent.width - 2 * Appearance.settings.padding
                        sourceComponent: root.componentFor(root.page)
                    }
                }
            }
        }
    }

    Component {
        id: wifiPage

        WifiPage {}
    }

    Component {
        id: bluetoothPage

        BluetoothPage {}
    }

    Component {
        id: audioPage

        AudioPage {}
    }

    Component {
        id: powerPage

        PowerPage {}
    }

    Component {
        id: workspacesPage

        WorkspacesPage {}
    }

    Component {
        id: appearancePage

        AppearancePage {}
    }
}
