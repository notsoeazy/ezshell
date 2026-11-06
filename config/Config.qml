pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    readonly property alias bar: adapter.bar
    readonly property alias osd: adapter.osd
    readonly property alias audio: adapter.audio
    readonly property alias brightness: adapter.brightness
    readonly property alias nightLight: adapter.nightLight
    readonly property alias workspaces: adapter.workspaces
    readonly property alias wallpaper: adapter.wallpaper
    readonly property alias battery: adapter.battery
    readonly property alias notifications: adapter.notifications
    readonly property alias idle: adapter.idle
    readonly property alias weather: adapter.weather
    readonly property alias sysinfo: adapter.sysinfo
    readonly property alias indicators: adapter.indicators
    readonly property alias animations: adapter.animations
    readonly property alias theme: adapter.theme

    FileView {
        id: fileView

        path: `${Paths.config}/config.json`
        watchChanges: true
        onFileChanged: reloadTimer.restart()
        onAdapterUpdated: writeTimer.restart()
        // The watcher only attaches after a successful read, so a file created on first run needs one.
        onSaved: reloadTimer.restart()
        onLoadFailed: error => {
            // First run: create the file with every default.
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter

            property BarConfig bar: BarConfig {}
            property OsdConfig osd: OsdConfig {}
            property StepConfig audio: StepConfig {}
            property StepConfig brightness: StepConfig {}
            property NightLightConfig nightLight: NightLightConfig {}
            property WorkspacesConfig workspaces: WorkspacesConfig {}
            property WallpaperConfig wallpaper: WallpaperConfig {}
            property BatteryConfig battery: BatteryConfig {}
            property NotificationsConfig notifications: NotificationsConfig {}
            property IdleConfig idle: IdleConfig {}
            property WeatherConfig weather: WeatherConfig {}
            property SysInfoConfig sysinfo: SysInfoConfig {}
            property IndicatorsConfig indicators: IndicatorsConfig {}
            property AnimationsConfig animations: AnimationsConfig {}
            property ThemeConfig theme: ThemeConfig {}
        }
    }

    // Debounce: editors often write a file in several steps, and assignments come in bursts.
    Timer {
        id: reloadTimer

        interval: 50
        onTriggered: fileView.reload()
    }

    Timer {
        id: writeTimer

        interval: 50
        onTriggered: fileView.writeAdapter()
    }

    // Named types instead of bare JsonObjects, so qmllint and qmlls can see the keys.
    component BarConfig: JsonObject {
        property bool showSeconds: false
        property bool use24Hour: false
    }

    component OsdConfig: JsonObject {
        property int hideDelay: 1500
    }

    component StepConfig: JsonObject {
        property real step: 0.05
    }

    component NightLightConfig: JsonObject {
        property bool enabled: false
        property int temperature: 4000
    }

    // special: { name, icon, exec, kind }; kind is "app" (one floating app) or "workspace" (docs/ISLAND.md).
    // Edit by reassigning the whole list: in-place edits inside a list<var> may not trigger a save.
    component WorkspacesConfig: JsonObject {
        property int shown: 5
        property list<var> special: [
            {
                name: "music",
                icon: "music_note",
                exec: "spotify",
                kind: "app"
            },
            {
                name: "term",
                icon: "terminal",
                exec: "kitty",
                kind: "workspace"
            }
        ]
    }

    component WallpaperConfig: JsonObject {
        property string path: ""
        // Scanned with its subfolders (hidden ones skipped) for the pickers, random, next and previous.
        property string folder: "~/Pictures/Wallpapers"
        // "fade", "wipe" or "none".
        property string transition: "fade"
        // "crop" (fill the screen), "fit" (whole image, black bars) or "center" (actual size).
        property string fill: "crop"
        // Slideshow: minutes between wallpapers, in folder order; 0 = off.
        property int interval: 0
    }

    component BatteryConfig: JsonObject {
        property real lowLevel: 0.15
    }

    component NotificationsConfig: JsonObject {
        property bool dnd: false
        // How long a banner stays, in ms. Critical notifications stay until dismissed.
        property int timeout: 5000
        property bool showInFullscreen: false
    }

    component IdleConfig: JsonObject {
        // Off by default so it doesn't double up with another idle manager (hypridle, caelestia).
        property bool enabled: false
        // Seconds of inactivity.
        property int lockAfter: 300
        property int screenOffAfter: 600
    }

    component WeatherConfig: JsonObject {
        // City name; "" finds the location from your IP address (falls back to Manila).
        property string location: ""
        // "metric" (°C) or "imperial" (°F).
        property string units: "metric"
        property int refreshMinutes: 30
    }

    component SysInfoConfig: JsonObject {
        // Milliseconds between samples, only while a dashboard tab shows stats.
        property int interval: 2000
    }

    component IndicatorsConfig: JsonObject {
        // Milliseconds a mic, camera or screen capture must last before its island indicator shows,
        // so screenshots and short device probes don't flash it.
        property int delay: 1000
    }

    component AnimationsConfig: JsonObject {
        // Multiplier for every animation: 0.25 shows them four times slower, 0 turns them off.
        property real speed: 1.0
    }

    component ThemeConfig: JsonObject {
        // Colors from the wallpaper (matugen); off = the built-in palette (black with Nord blue).
        property bool fromWallpaper: false
        // matugen scheme type: scheme-tonal-spot, scheme-content, scheme-expressive, scheme-fidelity,
        // scheme-fruit-salad, scheme-monochrome, scheme-neutral, scheme-rainbow, scheme-vibrant.
        property string scheme: "scheme-tonal-spot"
    }
}
