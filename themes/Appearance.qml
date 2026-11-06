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
        // Fraction of the morph that passes before new content starts fading in.
        readonly property real islandFadeInAt: 0.4

        function scaled(ms: real): int {
            return anim.speed > 0 ? Math.round(ms / anim.speed) : 0;
        }
    }

    component OsdTokens: QtObject {
        readonly property int width: 340
        readonly property int height: 48
        readonly property int padding: 16
        readonly property int gap: 12
        readonly property int icon: 22
        readonly property int trackHeight: 6
        readonly property int valueWidth: 36
    }

    component IslandTokens: QtObject {
        id: island

        readonly property int margin: 6
        readonly property int height: 44
        readonly property int padding: 14
        readonly property int maxWidth: 900
        readonly property int outlineWidth: 1
        readonly property real outlineOpacity: 0.4
        readonly property real alertOutlineOpacity: 0.5
        readonly property real dimmedOpacity: 0.35
        readonly property int dot: 8
        readonly property int dotGap: 6
        readonly property int activeDot: 22
        readonly property int chipHeight: 30
        readonly property int chipPadding: 12
        readonly property int trayIcon: 16
        // Fullscreen rest: a narrow pill parked above the screen edge, so transients drop in from the top.
        readonly property int hiddenWidth: 120
        // OutBack with islandOvershoot 1.2 passes its target by about 5% of the size change; this
        // fraction of the tallest mode is the room kept around it so the bounce never clips.
        readonly property real overshootFraction: 0.07
        readonly property OsdTokens osd: OsdTokens {}
        // Corner radius cap: short modes stay pills (height / 2), tall ones like the banner get this.
        readonly property int cornerRadius: 28
        readonly property int badge: 20
        // Status dot before a privacy or recording indicator (ISLAND.md: 6px).
        readonly property int indicatorDot: 6
        readonly property NotificationTokens notification: NotificationTokens {}
        readonly property MusicTokens music: MusicTokens {}
        readonly property EqualizerTokens equalizer: EqualizerTokens {}
        readonly property LauncherTokens launcher: LauncherTokens {}
        readonly property ExpandedTokens expanded: ExpandedTokens {}
        readonly property DashboardTokens dashboard: DashboardTokens {}
        // The island window: tallest mode plus margin and overshoot room, so the morph never resizes it.
        readonly property int panelHeight: Math.max(island.launcher.maxHeight, island.expanded.maxHeight)
        readonly property int tallestMode: Math.max(island.notification.maxHeight, island.panelHeight)
        readonly property int overshootMargin: Math.ceil(island.tallestMode * island.overshootFraction)
        readonly property int windowHeight: island.margin + island.tallestMode + island.overshootMargin
    }

    component NotificationTokens: QtObject {
        readonly property int width: 420
        readonly property int maxHeight: 120
        readonly property int padding: 16
        readonly property int gap: 12
        readonly property int icon: 40
        readonly property int iconRadius: 12
        readonly property int bodyLines: 2
    }

    component MusicTokens: QtObject {
        readonly property int width: 300
        readonly property int height: 34
        readonly property int padding: 8
        readonly property int art: 22
        readonly property int artRadius: 6
    }

    component EqualizerTokens: QtObject {
        readonly property int bars: 3
        readonly property int barWidth: 3
        readonly property int gap: 2
        readonly property int minHeight: 4
        readonly property int maxHeight: 14
        // One bounce duration per bar, different so the bars don't move in step.
        readonly property list<int> durations: [400, 250, 550]
    }

    component LauncherTokens: QtObject {
        id: launcher

        readonly property int width: 600
        readonly property int padding: 12
        readonly property int search: 48
        readonly property int row: 54
        readonly property int icon: 36
        readonly property int iconRadius: 10
        readonly property int maxResults: 5
        readonly property int footer: 28
        readonly property int rowGap: 4
        // Largest height (search, rows with gaps, footer, padding); the island window is sized from it.
        readonly property int rowsHeight: launcher.maxResults * (launcher.row + launcher.rowGap)
        readonly property int maxHeight: launcher.search + launcher.rowsHeight + launcher.footer + 2 * launcher.padding
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
    }

    // Expanded island: sections and dashboard tabs (docs/ISLAND.md, "Expanding the island").
    component ExpandedTokens: QtObject {
        // Dashboard tabs (ISLAND.md: 820 wide) and the narrower detail sections.
        readonly property int tabWidth: 820
        readonly property int sectionWidth: 560
        // Tallest section; the island window is sized from it, so sections must stay under it.
        readonly property int maxHeight: 560
        readonly property int padding: 24
        readonly property int tabGap: 28
        readonly property int gap: 12
        readonly property int header: 40
        readonly property int tabIndicator: 3
        readonly property int cardRadius: 16
        readonly property int cardPadding: 16
        readonly property int tile: 56
        readonly property int tileRadius: 16
        // Secondary text (a tile's state line) is the foreground color at this opacity.
        readonly property real secondaryOpacity: 0.7
        readonly property int row: 52
        readonly property int iconBox: 36
        readonly property int iconBoxRadius: 10
        // Lists scroll past this, so a section stays under maxHeight.
        readonly property int listMaxHeight: 312
    }

    // Dashboard cards (docs/ISLAND.md "Dashboard tabs" card table, frames 04, 14, 15).
    component DashboardTokens: QtObject {
        readonly property int heroClock: 46
        readonly property int headerIcon: 16
        readonly property int topRow: 128
        readonly property int statTile: 96
        readonly property int cardArt: 64
        readonly property int mediaArt: 112
        readonly property int artRadius: 12
        readonly property int playButton: 44
        readonly property int compactTile: 44
        readonly property int dayCell: 26
        readonly property int bigDayCell: 40
        readonly property int notificationRow: 64
        // Width shares of the bento rows (frame 14) and of the System tab (clock card : tiles).
        readonly property list<real> topShares: [2, 3, 4]
        readonly property list<real> bottomShares: [4, 3, 3]
        readonly property list<real> systemShares: [1, 2]
    }
}
