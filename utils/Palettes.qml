pragma Singleton

import Quickshell

// Built-in dark palettes as role → hex maps (role names as in Colors.qml, M3 "onX" written "xFg").
// Every palette keeps surface at #000000 so the island and window backgrounds stay pure black.
// `base` is Nord (nordtheme.com); Colors takes its initial defaults from it, and generated matugen
// themes keep `success` and `warning` from the active preset because matugen has neither role.
Singleton {
    id: root

    readonly property list<string> names: ["nord", "catppuccin", "gruvbox", "rose-pine", "tokyo-night"]
    readonly property var base: root.nord

    readonly property var nord: ({
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

    readonly property var catppuccin: ({
            surface: "#000000",
            surfaceFg: "#cdd6f4",
            surfaceVariantFg: "#bac2de",
            surfaceContainer: "#11111b",
            surfaceContainerHigh: "#1e1e2e",
            surfaceContainerHighest: "#313244",
            primary: "#cba6f7",
            primaryFg: "#11111b",
            primaryContainer: "#493668",
            primaryContainerFg: "#f5e0dc",
            secondary: "#89b4fa",
            secondaryFg: "#11111b",
            secondaryContainer: "#2d3f60",
            secondaryContainerFg: "#cdd6f4",
            tertiary: "#94e2d5",
            tertiaryContainer: "#284b47",
            tertiaryContainerFg: "#e6faf6",
            outline: "#585b70",
            outlineVariant: "#45475a",
            error: "#f38ba8",
            errorFg: "#11111b",
            errorContainer: "#582435",
            errorContainerFg: "#fbd0dc",
            success: "#a6e3a1",
            warning: "#f9e2af"
        })

    readonly property var gruvbox: ({
            surface: "#000000",
            surfaceFg: "#ebdbb2",
            surfaceVariantFg: "#d5c4a1",
            surfaceContainer: "#141617",
            surfaceContainerHigh: "#1d2021",
            surfaceContainerHighest: "#282828",
            primary: "#fabd2f",
            primaryFg: "#1d2021",
            primaryContainer: "#5c4412",
            primaryContainerFg: "#fbf1c7",
            secondary: "#83a598",
            secondaryFg: "#1d2021",
            secondaryContainer: "#2f413b",
            secondaryContainerFg: "#ebdbb2",
            tertiary: "#8ec07c",
            tertiaryContainer: "#32492b",
            tertiaryContainerFg: "#ebdbb2",
            outline: "#665c54",
            outlineVariant: "#504945",
            error: "#fb4934",
            errorFg: "#1d2021",
            errorContainer: "#5c1b14",
            errorContainerFg: "#f9d2ce",
            success: "#b8bb26",
            warning: "#fe8019"
        })

    readonly property var rosePine: ({
            surface: "#000000",
            surfaceFg: "#e0def4",
            surfaceVariantFg: "#908caa",
            surfaceContainer: "#12101a",
            surfaceContainerHigh: "#191724",
            surfaceContainerHighest: "#26233a",
            primary: "#c4a7e7",
            primaryFg: "#191724",
            primaryContainer: "#46385c",
            primaryContainerFg: "#e0def4",
            secondary: "#ebbcba",
            secondaryFg: "#191724",
            secondaryContainer: "#543b3d",
            secondaryContainerFg: "#e0def4",
            tertiary: "#9ccfd8",
            tertiaryContainer: "#2d484f",
            tertiaryContainerFg: "#e0def4",
            outline: "#6e6a86",
            outlineVariant: "#403d52",
            error: "#eb6f92",
            errorFg: "#191724",
            errorContainer: "#572335",
            errorContainerFg: "#f7c9d6",
            success: "#31748f",
            warning: "#f6c177"
        })

    readonly property var tokyoNight: ({
            surface: "#000000",
            surfaceFg: "#c0caf5",
            surfaceVariantFg: "#a9b1d6",
            surfaceContainer: "#10121c",
            surfaceContainerHigh: "#1a1b26",
            surfaceContainerHighest: "#24283b",
            primary: "#7aa2f7",
            primaryFg: "#15161e",
            primaryContainer: "#2c3d66",
            primaryContainerFg: "#c0caf5",
            secondary: "#bb9af7",
            secondaryFg: "#15161e",
            secondaryContainer: "#42355c",
            secondaryContainerFg: "#c0caf5",
            tertiary: "#7dcfff",
            tertiaryContainer: "#24475c",
            tertiaryContainerFg: "#d9f2ff",
            outline: "#565f89",
            outlineVariant: "#414868",
            error: "#f7768e",
            errorFg: "#15161e",
            errorContainer: "#5a2330",
            errorContainerFg: "#fcc8d2",
            success: "#9ece6a",
            warning: "#e0af68"
        })

    function get(name: string): var {
        const table = {
            nord: root.nord,
            catppuccin: root.catppuccin,
            gruvbox: root.gruvbox,
            "rose-pine": root.rosePine,
            "tokyo-night": root.tokyoNight
        };
        return table[name] ?? root.base;
    }
}
