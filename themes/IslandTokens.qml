pragma ComponentBehavior: Bound

import QtQuick
import qs.themes

// The island's tokens, reached as Appearance.island.
QtObject {
    id: island

    property int margin: 6
    readonly property int height: 44
    property int padding: 14
    property int sectionGap: 8
    property int itemSpacing: 8
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
    // Outer island pill corner radius (bound from Config.island.cornerRadius in Island.qml; decoupled from
    // Appearance.rounding.scale so the Appearance tab's Corner radius only scales inner cards and controls).
    property int cornerRadius: 22
    readonly property int expandedRadius: Math.max(island.cornerRadius, 28)
    readonly property int badge: 20
    // Status dot before a privacy or recording indicator (ISLAND.md: 6px).
    readonly property int indicatorDot: 6
    readonly property NotificationTokens notification: NotificationTokens {}
    readonly property MusicTokens music: MusicTokens {}
    readonly property EqualizerTokens equalizer: EqualizerTokens {}
    readonly property LauncherTokens launcher: LauncherTokens {}
    readonly property ExpandedTokens expanded: ExpandedTokens {}
    readonly property DashboardTokens dashboard: DashboardTokens {}
    readonly property ControlTokens control: ControlTokens {}
    readonly property PeekTokens peek: PeekTokens {}
    readonly property WallpaperTokens wallpapers: WallpaperTokens {}
    readonly property PolkitTokens polkit: PolkitTokens {}
    readonly property CaptureTokens capture: CaptureTokens {}
    readonly property KeybindTokens keybinds: KeybindTokens {}
    readonly property SwitcherTokens switcher: SwitcherTokens {}
    readonly property MessageTokens message: MessageTokens {}
    // The island window: tallest mode plus margin and overshoot room, so the morph never resizes it.
    readonly property int panelHeight: Math.max(island.launcher.maxHeight, island.expanded.maxHeight)
    readonly property int tallestMode: Math.max(island.notification.maxHeight, island.panelHeight)
    readonly property int overshootMargin: Math.ceil(island.tallestMode * island.overshootFraction)
    readonly property int windowHeight: island.margin + island.tallestMode + island.overshootMargin

    function scaled(px: real): int {
        return Appearance.rounding.scaled(px);
    }

    // Wallpapers section: one row in the dashboard-wide island, the selection centered with one full
    // neighbour and part of the next on each side; 16:9 like the screen.
    component WallpaperTokens: QtObject {
        readonly property int thumbWidth: 224
        readonly property int thumbHeight: 126
    }

    // Capture section cards (Screenshot / Record × Region / Window / Screen).
    component CaptureTokens: QtObject {
        readonly property int card: 96
    }

    // The message mode: as wide as its content between these, at least as tall as the OSD.
    component MessageTokens: QtObject {
        readonly property int minWidth: 300
        readonly property int maxWidth: 520
        readonly property int padding: 10
        readonly property int gap: 12
        // A screenshot's thumbnail: small and 16:9.
        readonly property int thumbWidth: 76
        readonly property int thumbHeight: 44
        // How far the thumbnail starts scaled down before it pops in.
        readonly property real popFrom: 0.8
        // A picked color's chip.
        readonly property int swatch: 28
    }

    // Polkit password prompt (above every other mode).
    component PolkitTokens: QtObject {
        readonly property int width: 460
        readonly property int padding: 20
        readonly property int gap: 12
        readonly property int icon: 32
        // How far the prompt shakes sideways after a wrong password.
        readonly property int shake: 10
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

    component NotificationTokens: QtObject {
        readonly property int width: 420
        readonly property int maxHeight: 120
        readonly property int padding: 16
        readonly property int gap: 12
        readonly property int icon: 40
        readonly property int iconRadius: island.scaled(12)
        readonly property int bodyLines: 2
    }

    // Now playing on a track change: as tall as the resting island and with its padding, so it reads as
    // the island widening, not a separate pill.
    component MusicTokens: QtObject {
        // The pill fits its content between these, so short titles stay centered.
        readonly property int minWidth: 260
        readonly property int maxWidth: 420
        readonly property int textMaxWidth: 260
        readonly property int art: 28
        readonly property int artRadius: island.scaled(8)
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
        readonly property int iconRadius: island.scaled(10)
        readonly property int maxResults: 5
        readonly property int footer: 28
        readonly property int rowGap: 4
        // Grid providers (emoji): square cells and the glyph size inside them.
        readonly property int cell: 52
        // Kaomoji cells: four to a row.
        readonly property int wideCell: 144
        readonly property int glyph: 28
        // Largest height (search, rows with gaps, footer, padding); the island window is sized from it.
        readonly property int rowsHeight: launcher.maxResults * (launcher.row + launcher.rowGap)
        readonly property int maxHeight: launcher.search + launcher.rowsHeight + launcher.footer + 2 * launcher.padding
    }

    // Expanded island: sections and dashboard tabs (docs/ISLAND.md, "Expanding the island").
    component ExpandedTokens: QtObject {
        id: expanded

        // Dashboard tabs (ISLAND.md: 820 wide) and the narrower detail sections.
        readonly property int tabWidth: 820
        readonly property int sectionWidth: 560
        // Tallest section; the island window is sized from it, so sections must stay under it.
        readonly property int maxHeight: 560
        readonly property int padding: 24
        // The tallest a page under the header can be; taller content (Control) scrolls inside it.
        readonly property int pageMaxHeight: expanded.maxHeight - 2 * expanded.padding - expanded.header - expanded.gap
        readonly property int tabGap: 14
        readonly property int gap: 12
        readonly property int header: 40
        readonly property int tabIndicator: 3
        readonly property int cardRadius: island.scaled(16)
        readonly property int cardPadding: 16
        // Secondary text (a tile's state line) is the foreground color at this opacity.
        readonly property real secondaryOpacity: 0.7
        readonly property int row: 52
        readonly property int iconBox: 36
        readonly property int iconBoxRadius: island.scaled(10)
        // Lists scroll past this, so a section stays under maxHeight.
        readonly property int listMaxHeight: 312
    }

    // Dashboard cards (docs/ISLAND.md "Dashboard tabs" card table, frames 04, 14, 15).
    // Hover peek (docs/ISLAND-R1.md): the resting line unchanged on top, a second line under it.
    component PeekTokens: QtObject {
        readonly property int width: 600
        readonly property int height: 88
        readonly property int dateRowHeight: 18
        readonly property int radius: Math.max(island.cornerRadius, 26)
        readonly property int bottomPadding: 12
        readonly property int appIcon: 16
        readonly property int appMaxWidth: 160
        readonly property int text: 12
        readonly property int chipArt: 26
        readonly property int chipArtRadius: island.scaled(7)
        readonly property int chipRadius: island.scaled(12)
        readonly property int chipPadding: 4
        // ms: hover this long before it opens; leave this long before it closes.
        readonly property int openDelay: 150
        readonly property int closeDelay: 250
    }

    // The Control tab (docs/ISLAND-R1.md): pill tiles, round buttons, level chips, the media row.
    component ControlTokens: QtObject {
        readonly property int gap: 8
        readonly property int tile: 44
        readonly property int tileIcon: 30
        readonly property int round: 44
        readonly property int cardRadius: island.scaled(16)
        readonly property int cardPadding: 8
        readonly property int cardSidePadding: 12
        // Volume / Microphone / Brightness level chips.
        readonly property int chip: 52
        readonly property int art: 36
        readonly property int artRadius: island.scaled(9)
        readonly property int title: 13
        readonly property int notifIcon: 28
        readonly property int notifIconRadius: island.scaled(8)
        // The notification center's empty state ("All caught up").
        readonly property int emptyHeight: 72
    }

    // The window switcher: a row of app tiles over the selected window's title.
    component SwitcherTokens: QtObject {
        readonly property int padding: 16
        readonly property int tile: 64
        readonly property int tileRadius: island.scaled(18)
        readonly property int icon: 40
        // Widest row of tiles before it scrolls; narrowest title line.
        readonly property int maxRow: 640
        readonly property int minText: 260
    }

    // The keybind cheat sheet: rows with key caps.
    component KeybindTokens: QtObject {
        readonly property int row: 36
        readonly property int rowRadius: island.scaled(10)
        readonly property int cap: 22
        readonly property int capPadding: 6
        readonly property int capRadius: island.scaled(6)
        readonly property int capGap: 7
    }

    component DashboardTokens: QtObject {
        // Each tab's width; the island morphs between them. Detail sections use expanded.sectionWidth.
        readonly property int controlWidth: 560
        // System tab sparklines; weather tab icons and capsules.
        readonly property int sparkline: 36
        readonly property real sparklineStroke: 1.5
        readonly property real sparklineFill: 0.18
        readonly property int weatherIcon: 40
        readonly property int weatherHero: 40
        readonly property int hourCapsule: 38
        readonly property int rangeBar: 6
        readonly property int dayLabel: 56
        readonly property int mediaWidth: 820
        readonly property int systemWidth: 720
        readonly property int weatherWidth: 560
        readonly property int calendarWidth: 440
        readonly property int heroClock: 46
        readonly property int headerIcon: 16
        readonly property int mediaArt: 80
        // The mixer's level column ("100%", "Muted").
        readonly property int mixerPercent: 48
        readonly property int artRadius: island.scaled(12)
        readonly property int playButton: 44
        readonly property int dayCell: 26
        readonly property int bigDayCell: 40
    }
}
