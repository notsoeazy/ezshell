pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Things the shell remembers between runs that are not preferences: which
// toggles were left on. Kept apart from Config so that hand-edited settings
// and machine-written state never share a file.
Singleton {
    id: root

    readonly property string path: `${Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`}/ezshell/state.json`
    property alias doNotDisturb: adapter.doNotDisturb
    property alias nightLight: adapter.nightLight
    property alias nightLightTemperature: adapter.nightLightTemperature
    property alias appUsage: adapter.appUsage
    property alias wallpaper: adapter.wallpaper
    property alias silencedApps: adapter.silencedApps

    FileView {
        path: root.path
        printErrors: false

        Component.onCompleted: waitForJob()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter

            property bool doNotDisturb: false
            property bool nightLight: false
            // Colour temperature in kelvin; lower is warmer.
            property int nightLightTemperature: 4000
            // How many times each app has been launched (id -> count), to
            // rank the launcher's results.
            property var appUsage: ({})
            // Full path of the wallpaper that is set; empty until one is chosen.
            property string wallpaper: ""
            // Apps whose notifications do not raise a banner (their names).
            property var silencedApps: []
        }
    }
}
