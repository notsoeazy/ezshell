pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    // Not themeable, so these live outside the adapter. The island stays black in every theme.
    readonly property color transparent: "transparent"
    readonly property color island: "#000000"
    // Bound from Config.theme.cardOpacity in Island.qml; tints inner card containers while keeping surface pure black.
    property real cardOpacity: 1.0
    readonly property alias baseContainer: adapter.surfaceContainer
    readonly property alias baseContainerHigh: adapter.surfaceContainerHigh
    readonly property alias baseContainerHighest: adapter.surfaceContainerHighest

    // M3 "onX" roles are named "xFg": QML rejects declared properties that start with "on" + a capital.
    readonly property alias surface: adapter.surface
    readonly property alias surfaceFg: adapter.surfaceFg
    readonly property alias surfaceVariantFg: adapter.surfaceVariantFg
    readonly property color surfaceContainer: Qt.alpha(root.baseContainer, root.cardOpacity)
    readonly property color surfaceContainerHigh: Qt.alpha(root.baseContainerHigh, root.cardOpacity)
    readonly property color surfaceContainerHighest: Qt.alpha(root.baseContainerHighest, root.cardOpacity)
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

    // Generated state, so it lives in XDG_STATE_HOME, out of the dotfiles. The Theme service writes it;
    // the only write from here is the first run, which creates it from the defaults below.
    FileView {
        id: fileView

        // Same as Paths.state, resolved here because themes/ may not import config/.
        path: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/ezshell/theme.json`
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

            // Defaults: the built-in palette (utils/Palettes.qml), black with Nord blue accents.
            property color surface: Palettes.base.surface
            property color surfaceFg: Palettes.base.surfaceFg
            property color surfaceVariantFg: Palettes.base.surfaceVariantFg
            property color surfaceContainer: Palettes.base.surfaceContainer
            property color surfaceContainerHigh: Palettes.base.surfaceContainerHigh
            property color surfaceContainerHighest: Palettes.base.surfaceContainerHighest
            property color primary: Palettes.base.primary
            property color primaryFg: Palettes.base.primaryFg
            property color primaryContainer: Palettes.base.primaryContainer
            property color primaryContainerFg: Palettes.base.primaryContainerFg
            property color secondary: Palettes.base.secondary
            property color secondaryFg: Palettes.base.secondaryFg
            property color secondaryContainer: Palettes.base.secondaryContainer
            property color secondaryContainerFg: Palettes.base.secondaryContainerFg
            property color tertiary: Palettes.base.tertiary
            property color tertiaryContainer: Palettes.base.tertiaryContainer
            property color tertiaryContainerFg: Palettes.base.tertiaryContainerFg
            property color outline: Palettes.base.outline
            property color outlineVariant: Palettes.base.outlineVariant
            property color error: Palettes.base.error
            property color errorFg: Palettes.base.errorFg
            property color errorContainer: Palettes.base.errorContainer
            property color errorContainerFg: Palettes.base.errorContainerFg
            property color success: Palettes.base.success
            property color warning: Palettes.base.warning
        }
    }

    Timer {
        id: reloadTimer

        interval: 50
        onTriggered: fileView.reload()
    }
}
