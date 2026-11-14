pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.theme
import qs.components.containers
import qs.components.controls
import qs.modules.settings
import qs.modules.settings.pages

// The settings window: an ordinary floating window, created when opened and
// destroyed when closed. A sidebar of sections, and the section's page.
Scope {
    id: root

    // In the order of SettingsState.sections. `gap` starts a new cluster in the
    // sidebar: connections, the system, the shell, about.
    readonly property list<var> sections: [
        {
            title: "Network",
            icon: "wifi",
            component: network
        },
        {
            title: "Bluetooth",
            icon: "bluetooth",
            component: bluetooth
        },
        {
            title: "Sound",
            icon: "volume_up",
            gap: true,
            component: sound
        },
        {
            title: "Display",
            icon: "monitor",
            component: display
        },
        {
            title: "Notifications",
            icon: "notifications",
            component: notifications
        },
        {
            title: "Lock Screen",
            icon: "lock",
            component: lock
        },
        {
            title: "Capture",
            icon: "screenshot_region",
            component: capture
        },
        {
            title: "Appearance",
            icon: "palette",
            gap: true,
            component: appearance
        },
        {
            title: "Island",
            icon: "dock_to_bottom",
            component: island
        },
        {
            title: "Wallpaper",
            icon: "wallpaper",
            component: wallpaper
        },
        {
            title: "Launcher",
            icon: "search",
            component: launcher
        },
        {
            title: "About",
            icon: "info",
            gap: true,
            component: about
        }
    ]

    Component {
        id: network

        NetworkPage {}
    }

    Component {
        id: bluetooth

        BluetoothPage {}
    }

    Component {
        id: sound

        SoundPage {}
    }

    Component {
        id: display

        DisplayPage {}
    }

    Component {
        id: notifications

        NotificationsPage {}
    }

    Component {
        id: lock

        LockPage {}
    }

    Component {
        id: capture

        CapturePage {}
    }

    Component {
        id: appearance

        AppearancePage {}
    }

    Component {
        id: island

        IslandPage {}
    }

    Component {
        id: wallpaper

        WallpaperPage {}
    }

    Component {
        id: launcher

        LauncherPage {}
    }

    Component {
        id: about

        AboutPage {}
    }

    LazyLoader {
        active: SettingsState.visible

        FloatingWindow {
            title: "ezshell settings"
            color: Theme.color.surface
            implicitWidth: Tokens.spacing.xxxl * 28
            implicitHeight: Tokens.spacing.xxxl * 21

            onClosed: SettingsState.close()

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Sidebar {
                    Layout.fillHeight: true
                    Layout.preferredWidth: Tokens.spacing.xxxl * 6
                    Layout.minimumWidth: Layout.preferredWidth
                    Layout.maximumWidth: Layout.preferredWidth
                    Layout.margins: Tokens.spacing.md
                    title: "Settings"
                    items: root.sections
                    current: SettingsState.section
                    onSelected: index => SettingsState.section = index
                }

                Separator {
                    Layout.fillHeight: true
                }

                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    sourceComponent: root.sections[SettingsState.section].component
                }
            }
        }
    }
}
