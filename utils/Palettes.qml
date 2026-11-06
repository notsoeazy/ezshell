pragma Singleton

import Quickshell

// Built-in palettes as role → hex maps (role names as in Colors.qml, M3 "onX" written "xFg").
// `base` is the default: black surfaces with Nord blue accents (nordtheme.com). Colors takes its defaults
// from it, and Theme writes it to theme.json when wallpaper theming is off. Matugen has no success or
// warning roles, so generated themes keep these two from here.
Singleton {
    readonly property var base: ({
            surface: "#000000",
            surfaceFg: "#eceff4",
            surfaceVariantFg: "#d8dee9",
            surfaceContainer: "#111317",
            surfaceContainerHigh: "#1b1e24",
            surfaceContainerHighest: "#262a32",
            primary: "#88c0d0",
            primaryFg: "#2e3440",
            primaryContainer: "#3b5470",
            primaryContainerFg: "#eceff4",
            secondary: "#81a1c1",
            secondaryFg: "#2e3440",
            secondaryContainer: "#2e3a4d",
            secondaryContainerFg: "#d8dee9",
            tertiary: "#8fbcbb",
            tertiaryContainer: "#2f4746",
            tertiaryContainerFg: "#e5f2f1",
            outline: "#4c566a",
            outlineVariant: "#3b4252",
            error: "#bf616a",
            errorFg: "#000000",
            errorContainer: "#4c1d22",
            errorContainerFg: "#f2c9cd",
            success: "#a3be8c",
            warning: "#ebcb8b"
        })
}
