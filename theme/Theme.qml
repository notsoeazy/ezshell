pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme

// Colours. `color` is the scheme in use: the fixed HIG-style palette, or one
// taken from the Material palette generated from the wallpaper (written by
// the Theming service to a file this reads). `material` is that palette
// itself, under Material's names, for anything that wants a role of its own.
Singleton {
    id: root

    readonly property string path: `${Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`}/ezshell/theme/scheme.json`
    // Whether a generated palette is in use.
    readonly property bool dynamic: Config.theming.dynamic && generated
    // Set once a palette has been read from the file.
    property bool generated

    readonly property ColorScheme light: dynamic ? generatedLight : fixedLight
    readonly property ColorScheme dark: dynamic ? generatedDark : fixedDark
    readonly property ColorScheme color: Config.appearance.dark ? dark : light
    readonly property MaterialScheme material: Config.appearance.dark ? materialDark : materialLight
    readonly property MaterialScheme materialLight: MaterialScheme {}
    readonly property MaterialScheme materialDark: MaterialScheme {}

    readonly property list<string> accentNames: ["blue", "green", "red", "orange", "yellow", "indigo", "purple", "pink", "teal", "grey"]
    // The accent: the palette's primary, or the colour chosen in settings.
    readonly property color accent: dynamic ? material.primary : accentNames.includes(Config.appearance.accent) ? color[Config.appearance.accent] : color.blue
    // A quiet fill in the accent's hue, and what is drawn on it.
    readonly property color accentContainer: dynamic ? material.primaryContainer : Qt.alpha(accent, 0.18)
    readonly property color onAccentContainer: dynamic ? material.onPrimaryContainer : accent

    // Read a palette: { light: { role: "#hex" }, dark: { ... } }.
    function load(text: string): void {
        let data;
        try {
            data = JSON.parse(text);
        } catch (error) {
            return;
        }
        for (const [scheme, colours] of [[materialLight, data.light], [materialDark, data.dark]]) {
            if (!colours)
                return;
            for (const [role, value] of Object.entries(colours)) {
                if (scheme.hasOwnProperty(role))
                    scheme[role] = value;
            }
        }
        generated = true;
    }

    FileView {
        path: root.path
        printErrors: false
        watchChanges: true
        // Block for the first read, so the shell never starts in the fixed
        // colours and then changes.
        Component.onCompleted: waitForJob()
        onFileChanged: reload()
        onLoaded: root.load(text())
    }

    readonly property ColorScheme generatedLight: GeneratedScheme {
        material: root.materialLight
        base: root.fixedLight
        isDark: false
    }
    readonly property ColorScheme generatedDark: GeneratedScheme {
        material: root.materialDark
        base: root.fixedDark
        isDark: true
    }

    readonly property ColorScheme fixedLight: ColorScheme {
        surface: "#f2f2f7"
        surfaceRaised: "#ffffff"
        island: "#ffffff"
        scrim: Qt.rgba(0, 0, 0, 0.35)

        label: "#000000"
        labelSecondary: Qt.alpha("#3c3c43", 0.6)
        labelTertiary: Qt.alpha("#3c3c43", 0.3)
        labelQuaternary: Qt.alpha("#3c3c43", 0.18)
        fill: Qt.alpha("#787880", 0.2)
        fillSecondary: Qt.alpha("#787880", 0.16)
        fillTertiary: Qt.alpha("#767680", 0.12)
        separator: Qt.alpha("#3c3c43", 0.29)
        control: "#ffffff"
        thumb: "#ffffff"
        onAccent: "#ffffff"

        blue: "#007aff"
        green: "#34c759"
        red: "#ff3b30"
        orange: "#ff9500"
        yellow: "#ffcc00"
        indigo: "#5856d6"
        purple: "#af52de"
        pink: "#ff2d55"
        teal: "#30b0c7"
        grey: "#8e8e93"
    }

    readonly property ColorScheme fixedDark: ColorScheme {
        surface: "#1c1c1e"
        surfaceRaised: "#2c2c2e"
        island: "#000000"
        scrim: Qt.rgba(0, 0, 0, 0.35)

        label: "#ffffff"
        labelSecondary: Qt.alpha("#ebebf5", 0.6)
        labelTertiary: Qt.alpha("#ebebf5", 0.3)
        labelQuaternary: Qt.alpha("#ebebf5", 0.18)
        fill: Qt.alpha("#787880", 0.36)
        fillSecondary: Qt.alpha("#787880", 0.32)
        fillTertiary: Qt.alpha("#767680", 0.24)
        separator: Qt.alpha("#545458", 0.6)
        control: "#636366"
        thumb: "#ffffff"
        onAccent: "#ffffff"

        blue: "#0a84ff"
        green: "#30d158"
        red: "#ff453a"
        orange: "#ff9f0a"
        yellow: "#ffd60a"
        indigo: "#5e5ce6"
        purple: "#bf5af2"
        pink: "#ff375f"
        teal: "#40c8e0"
        grey: "#8e8e93"
    }
}
