pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme
import qs.components
import qs.components.containers
import qs.modules.settings

SettingsPage {
    id: root

    // What the shell uses from the system, and what is lost without it.
    readonly property list<var> tools: [
        {
            command: "brightnessctl",
            use: "Brightness"
        },
        {
            command: "hyprsunset",
            use: "Night light"
        },
        {
            command: "nmcli",
            use: "Wi-Fi network name"
        },
        {
            command: "cliphist",
            use: "Clipboard history"
        },
        {
            command: "wl-copy",
            use: "Copying from the launcher"
        },
        {
            command: "magick",
            use: "Wallpaper thumbnails, screenshots"
        },
        {
            command: "grim",
            use: "Screenshots"
        },
        {
            command: "swappy",
            use: "Editing screenshots"
        },
        {
            command: "gpu-screen-recorder",
            use: "Screen recording"
        },
        {
            command: "matugen",
            use: "Colours from the wallpaper"
        }
    ]
    // Names of the tools found.
    property list<string> found: []

    Group {
        Layout.fillWidth: true
        title: "ezshell"

        ListRow {
            Layout.fillWidth: true
            title: "Settings file"
            subtitle: Config.path
            icon: "settings"
            interactive: false
        }

        ListRow {
            Layout.fillWidth: true
            title: "Saved state"
            subtitle: ShellState.path
            icon: "save"
            interactive: false
        }

        ListRow {
            Layout.fillWidth: true
            title: "Icon font"
            subtitle: Qt.fontFamilies().includes(Tokens.font.icon) ? Tokens.font.icon : `${Tokens.font.icon} is not installed (ttf-material-symbols-variable)`
            icon: "font_download"
            interactive: false
            separator: false
        }
    }

    Group {
        Layout.fillWidth: true
        title: "Tools"
        note: "Each is optional: without one, only its feature is missing."

        Repeater {
            model: root.tools

            ListRow {
                id: row

                required property var modelData
                required property int index
                readonly property bool present: root.found.includes(modelData.command)

                Layout.fillWidth: true
                title: modelData.use
                subtitle: modelData.command
                interactive: false
                separator: index < root.tools.length - 1

                Icon {
                    name: row.present ? "check_circle" : "cancel"
                    filled: true
                    color: row.present ? Theme.color.green : Theme.color.red
                }

                Label {
                    text: row.present ? "Installed" : "Missing"
                    level: Label.Secondary
                }
            }
        }
    }

    // Prints the name of each tool that exists.
    Process {
        running: true
        command: ["sh", "-c", 'for tool; do command -v "$tool" >/dev/null && echo "$tool"; done', "sh", ...root.tools.map(tool => tool.command)]

        stdout: StdioCollector {
            onStreamFinished: root.found = text.split("\n").filter(name => name.length > 0)
        }
    }
}
