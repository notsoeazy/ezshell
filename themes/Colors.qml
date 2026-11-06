pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Not themeable, so these live outside the adapter. The island stays black in every theme.
    readonly property color transparent: "transparent"
    readonly property color island: "#000000"

    // M3 "onX" roles are named "xFg": QML rejects declared properties that start with "on" + a capital.
    readonly property alias surface: adapter.surface
    readonly property alias surfaceFg: adapter.surfaceFg
    readonly property alias surfaceVariantFg: adapter.surfaceVariantFg
    readonly property alias surfaceContainer: adapter.surfaceContainer
    readonly property alias surfaceContainerHigh: adapter.surfaceContainerHigh
    readonly property alias surfaceContainerHighest: adapter.surfaceContainerHighest
    readonly property alias primary: adapter.primary
    readonly property alias primaryFg: adapter.primaryFg
    readonly property alias primaryContainer: adapter.primaryContainer
    readonly property alias primaryContainerFg: adapter.primaryContainerFg
    readonly property alias secondary: adapter.secondary
    readonly property alias secondaryFg: adapter.secondaryFg
    readonly property alias secondaryContainer: adapter.secondaryContainer
    readonly property alias secondaryContainerFg: adapter.secondaryContainerFg
    readonly property alias tertiary: adapter.tertiary
    readonly property alias tertiaryContainer: adapter.tertiaryContainer
    readonly property alias tertiaryContainerFg: adapter.tertiaryContainerFg
    readonly property alias outline: adapter.outline
    readonly property alias outlineVariant: adapter.outlineVariant
    readonly property alias error: adapter.error
    readonly property alias errorFg: adapter.errorFg
    readonly property alias errorContainer: adapter.errorContainer
    readonly property alias errorContainerFg: adapter.errorContainerFg
    readonly property alias success: adapter.success
    readonly property alias warning: adapter.warning

    // The shell never writes colors after first run; whatever generates theme.json owns it.
    FileView {
        id: fileView

        // Same dir as Paths.config, resolved here because themes/ may not import config/.
        path: `${Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"}/ezshell/theme.json`
        watchChanges: true
        onFileChanged: reloadTimer.restart()
        // The watcher only attaches after a successful read, so a file created on first run needs one.
        onSaved: reloadTimer.restart()
        onLoadFailed: error => {
            // First run: create the file with the defaults below.
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter

            // Dark defaults from the Figma variables (docs/FIGMA.md). secondary, secondaryFg and
            // errorFg aren't in Figma; they are the matching Material 3 baseline values.
            property color surface: "#121318"
            property color surfaceFg: "#e3e2e9"
            property color surfaceVariantFg: "#c5c6d0"
            property color surfaceContainer: "#1e1f25"
            property color surfaceContainerHigh: "#292a2f"
            property color surfaceContainerHighest: "#34343a"
            property color primary: "#b1c5ff"
            property color primaryFg: "#172e60"
            property color primaryContainer: "#2f4578"
            property color primaryContainerFg: "#d9e2ff"
            property color secondary: "#c0c6dc"
            property color secondaryFg: "#2a3042"
            property color secondaryContainer: "#3f4759"
            property color secondaryContainerFg: "#dbe2f9"
            property color tertiary: "#e0bbdd"
            property color tertiaryContainer: "#5a3d59"
            property color tertiaryContainerFg: "#fdd7f9"
            property color outline: "#8f909a"
            property color outlineVariant: "#45464f"
            property color error: "#ffb4ab"
            property color errorFg: "#690005"
            property color errorContainer: "#93000a"
            property color errorContainerFg: "#ffdad6"
            property color success: "#9ad58e"
            property color warning: "#ffb86b"
        }
    }

    Timer {
        id: reloadTimer

        interval: 50
        onTriggered: fileView.reload()
    }
}
