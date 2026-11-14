pragma Singleton

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.modules.island
import qs.modules.settings

// What the launcher's actions mode offers. Adding an action means adding it
// here and nowhere else.
Singleton {
    // The fixed actions, and one for each special workspace that exists.
    readonly property list<var> list: [...fixed, ...Hypr.specials.map(name => ({
                    title: `Toggle ${name} workspace`,
                    icon: Config.island.specialIcons[name] ?? "layers",
                    keywords: "special scratchpad",
                    run: () => Hypr.toggleSpecial(name)
                }))]
    readonly property list<var> fixed: [
        {
            title: "Screenshot",
            icon: "screenshot_region",
            keywords: "capture window area region",
            run: () => Capture.screenshotSoon("")
        },
        {
            title: "Screenshot the Whole Screen",
            icon: "screenshot_monitor",
            keywords: "capture full",
            run: () => soonScreen.restart()
        },
        {
            title: "Record the Screen",
            icon: "videocam",
            keywords: "capture video start stop",
            run: () => Capture.recordSoon("screen")
        },
        {
            title: "Record the Screen with Sound",
            icon: "videocam",
            keywords: "capture video audio start stop",
            run: () => Capture.recordSoon("sound")
        },
        {
            title: "Record an Area",
            icon: "crop",
            keywords: "capture video region window",
            run: () => Capture.recordSoon("region")
        },
        {
            title: "Settings",
            icon: "settings",
            keywords: "preferences options configure",
            run: () => SettingsState.open("")
        },
        {
            title: "Control Panel",
            icon: "tune",
            keywords: "quick settings",
            run: () => IslandState.openPanel("")
        },
        {
            title: "Wi-Fi",
            icon: "wifi",
            keywords: "network internet",
            run: () => IslandState.openPanel("wifi")
        },
        {
            title: "Bluetooth",
            icon: "bluetooth",
            keywords: "devices",
            run: () => IslandState.openPanel("bluetooth")
        },
        {
            title: "Sound",
            icon: "volume_up",
            keywords: "audio output input microphone",
            run: () => IslandState.openPanel("audio")
        },
        {
            title: "Night Light Settings",
            icon: "bedtime",
            keywords: "temperature warm",
            run: () => IslandState.openPanel("nightlight")
        },
        {
            title: "Notifications",
            icon: "notifications",
            run: () => IslandState.open("notifications")
        },
        {
            title: "Clear Notifications",
            icon: "clear_all",
            run: () => Notifications.clear()
        },
        {
            title: "Wallpaper",
            icon: "wallpaper",
            keywords: "background picture",
            run: () => IslandState.open("wallpaper")
        },
        {
            title: "Calendar",
            icon: "calendar_month",
            keywords: "date month",
            run: () => IslandState.open("calendar")
        },
        {
            title: "Session",
            icon: "power_settings_new",
            keywords: "lock log out restart reboot shut down power off",
            run: () => IslandState.open("session")
        },
        {
            title: "Lock",
            icon: "lock",
            keywords: "screen",
            run: () => Session.lock()
        },
        {
            title: "Toggle Night Light",
            icon: "bedtime",
            keywords: "warm",
            run: () => NightLight.setEnabled(!NightLight.enabled)
        },
        {
            title: "Toggle Do Not Disturb",
            icon: "notifications_off",
            keywords: "dnd silence",
            run: () => ShellState.doNotDisturb = !ShellState.doNotDisturb
        },
        {
            title: "Toggle Keep Awake",
            icon: "coffee",
            keywords: "idle caffeine",
            run: () => KeepAwake.toggle()
        },
        {
            title: "Toggle Mute",
            icon: "volume_off",
            keywords: "sound volume",
            run: () => Audio.toggleMute()
        },
        {
            title: "Toggle Microphone",
            icon: "mic_off",
            keywords: "mute",
            run: () => Audio.toggleMicMute()
        },
        {
            title: "Toggle Dark Mode",
            icon: "dark_mode",
            keywords: "light appearance theme",
            run: () => Config.appearance.dark = !Config.appearance.dark
        }
    ]

    // A whole-screen shot waits for the launcher to close, or it is in it.
    Timer {
        id: soonScreen

        interval: Tokens.motion.spatialSlow.duration
        onTriggered: Capture.screenshotScreen("")
    }
}
