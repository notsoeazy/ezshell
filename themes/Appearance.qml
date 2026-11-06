pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property SpacingTokens spacing: SpacingTokens {}
    readonly property RoundingTokens rounding: RoundingTokens {}
    readonly property FontTokens font: FontTokens {}
    readonly property AnimTokens anim: AnimTokens {}
    readonly property IslandTokens island: IslandTokens {}
    readonly property LockTokens lock: LockTokens {}
    readonly property SettingsTokens settings: SettingsTokens {}
    readonly property ControlTokens control: ControlTokens {}

    // Named types instead of bare QtObjects, so qmllint and qmlls can see the members.
    component SpacingTokens: QtObject {
        readonly property int small: 4
        readonly property int normal: 8
        readonly property int large: 16
    }

    component RoundingTokens: QtObject {
        readonly property int small: 8
        readonly property int normal: 16
        readonly property int full: 1000
    }

    component FontSizeTokens: QtObject {
        readonly property int small: 11
        readonly property int normal: 13
        readonly property int clock: 15
        readonly property int title: 15
        readonly property int large: 16
        readonly property int icon: 18
        readonly property int display: 96
    }

    component FontTokens: QtObject {
        // The design uses Google Sans Flex; Inter stands in until it is installed.
        readonly property string family: "Inter"
        readonly property string icons: "Material Symbols Rounded"
        readonly property FontSizeTokens size: FontSizeTokens {}
    }

    component AnimTokens: QtObject {
        id: anim

        // Multiplier for every animation duration: 0.25 = four times slower, 0 = instant. Bound from
        // Config.animations.speed in Island.qml (themes can't read config).
        property real speed: 1
        readonly property int fast: 150
        readonly property int normal: 250
        readonly property int slow: 400
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> emphasized: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property int islandExpand: 400
        readonly property int islandCollapse: 275
        readonly property real islandOvershoot: 1.2
        readonly property int islandFadeOut: 100
        readonly property int islandFadeIn: 150
        readonly property int wallpaper: 700
        // Fraction of the morph that passes before new content starts fading in.
        readonly property real islandFadeInAt: 0.4

        function scaled(ms: real): int {
            return anim.speed > 0 ? Math.round(ms / anim.speed) : 0;
        }
    }

    component LockTokens: QtObject {
        readonly property int inputWidth: 320
        readonly property int inputHeight: 48
        readonly property real scrimOpacity: 0.55
    }

    component SettingsTokens: QtObject {
        readonly property int width: 880
        readonly property int height: 620
        readonly property int sidebar: 220
        readonly property int padding: 24
        readonly property int sectionPadding: 16
        readonly property int row: 48
        readonly property int gap: 12
        readonly property int previewWidth: 320
        readonly property int previewHeight: 180
        readonly property int thumbWidth: 152
        readonly property int thumbHeight: 86
        readonly property int swatch: 44
        readonly property int selectedBorder: 2
    }

    // Generic controls (components/Styled*), shared by the settings app and the island.
    component ControlTokens: QtObject {
        readonly property int height: 36
        readonly property int fieldWidth: 260
        readonly property int narrowFieldWidth: 140
        readonly property int numberWidth: 80
        readonly property int sliderWidth: 220
        readonly property int switchWidth: 44
        readonly property int switchHeight: 24
        readonly property int knobInset: 3
        readonly property int trackHeight: 6
        readonly property real disabledOpacity: 0.4
        readonly property int borderWidth: 1
        // The disc behind a check mark on a thumbnail.
        readonly property int check: 22
    }
}
