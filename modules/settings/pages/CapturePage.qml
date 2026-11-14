import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.settings

SettingsPage {
    id: root

    readonly property list<string> actionTitles: ["Edit", "Copy", "Save"]
    readonly property list<string> modeTitles: ["Screen", "With sound", "Area"]

    Group {
        Layout.fillWidth: true
        title: "Screenshots"
        note: "A screenshot starts on a frozen picture of the screen: click a window, drag an area, or press Return for the whole screen. Shortcuts and commands can name any of the three actions; this is the one used when none is named."

        ListRow {
            Layout.fillWidth: true
            title: "After a screenshot"
            icon: "screenshot_region"
            interactive: false

            SegmentedControl {
                segments: root.actionTitles
                current: Math.max(0, Capture.actions.indexOf(Config.capture.screenshotAction))
                onSelected: index => Config.capture.screenshotAction = Capture.actions[index]
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Editor"
            subtitle: "The command Edit opens the picture with"
            icon: "edit"
            interactive: false

            Field {
                value: Config.capture.editor.join(" ")
                onCommitted: text => Config.capture.editor = text.split(" ").filter(part => part.length > 0)
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Folder"
            subtitle: "Where Save and copy puts them; ~ is your home"
            icon: "folder"
            interactive: false
            separator: false

            Field {
                value: Config.capture.screenshotDirectory
                onCommitted: text => Config.capture.screenshotDirectory = text
            }
        }
    }

    Group {
        Layout.fillWidth: true
        title: "Recordings"
        note: "Recording uses gpu-screen-recorder. While one runs, the island shows a red dot and the time; stop it there, from the control panel, or with the same shortcut."

        ListRow {
            Layout.fillWidth: true
            title: "The record button records"
            icon: "videocam"
            interactive: false

            SegmentedControl {
                segments: root.modeTitles
                current: Math.max(0, Capture.recordModes.indexOf(Config.capture.recordMode))
                onSelected: index => Config.capture.recordMode = Capture.recordModes[index]
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Record the microphone too"
            subtitle: "When recording with sound"
            icon: "mic"
            interactive: false

            Switch {
                checked: Config.capture.recordMicrophone
                onToggled: Config.capture.recordMicrophone = !Config.capture.recordMicrophone
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Frames per second"
            icon: "speed"
            interactive: false

            Stepper {
                value: Config.capture.recordFps
                from: 15
                to: 144
                step: 15
                onMoved: value => Config.capture.recordFps = value
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Folder"
            icon: "folder"
            interactive: false
            separator: false

            Field {
                value: Config.capture.recordingDirectory
                onCommitted: text => Config.capture.recordingDirectory = text
            }
        }
    }
}
