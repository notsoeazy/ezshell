pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.modules.island
import qs.modules.settings

// Global shortcuts: everything a key can be bound to in the Hyprland config,
// as `hl.dsp.global("ezshell:<name>")` (or `global, ezshell:<name>`). With
// Ipc, one of the two services that reach into modules.
//
// The linter cannot see into Quickshell's GlobalShortcut type, hence:
// qmllint disable unresolved-type
Scope {
    GlobalShortcut {
        appid: "ezshell"
        name: "launcher"
        description: "Open or close the launcher"
        onPressed: IslandState.requested === "launcher" ? IslandState.close() : IslandState.openLauncher("")
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "controlpanel"
        description: "Open or close the control panel"
        onPressed: IslandState.toggle("controlpanel")
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "notifications"
        description: "Open or close the notification list"
        onPressed: IslandState.toggle("notifications")
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "clearNotifications"
        description: "Dismiss every notification"
        onPressed: Notifications.clear()
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "doNotDisturb"
        description: "Turn Do Not Disturb on or off"
        onPressed: ShellState.doNotDisturb = !ShellState.doNotDisturb
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "session"
        description: "Open or close the session view"
        onPressed: IslandState.toggle("session")
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "lock"
        description: "Lock the screen"
        onPressed: Session.lock()
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "settings"
        description: "Open or close settings"
        onPressed: SettingsState.toggle()
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "wallpaper"
        description: "Open or close the wallpaper selector"
        onPressed: IslandState.toggle("wallpaper")
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "calendar"
        description: "Open or close the calendar"
        onPressed: IslandState.toggle("calendar")
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "close"
        description: "Close whatever the island has open"
        onPressed: IslandState.close()
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "screenshot"
        description: "Take a screenshot of a window or an area"
        onPressed: Capture.screenshot("")
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "screenshotEdit"
        description: "Take a screenshot and open it in the editor"
        onPressed: Capture.screenshot("edit")
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "screenshotCopy"
        description: "Take a screenshot and copy it"
        onPressed: Capture.screenshot("copy")
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "screenshotSave"
        description: "Take a screenshot, save it and copy it"
        onPressed: Capture.screenshot("save")
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "screenshotScreen"
        description: "Take a screenshot of the whole screen"
        onPressed: Capture.screenshotScreen("")
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "record"
        description: "Start or stop recording the screen"
        onPressed: Capture.record("")
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "recordScreen"
        description: "Start or stop recording the screen, without sound"
        onPressed: Capture.record("screen")
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "recordSound"
        description: "Start or stop recording the screen with sound"
        onPressed: Capture.record("sound")
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "recordRegion"
        description: "Start or stop recording an area"
        onPressed: Capture.record("region")
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "special"
        description: "Show or hide the special workspace last shown"
        onPressed: Hypr.toggleSpecial("")
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "volumeUp"
        description: "Raise the volume"
        onPressed: Audio.changeVolume(0.05)
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "volumeDown"
        description: "Lower the volume"
        onPressed: Audio.changeVolume(-0.05)
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "mute"
        description: "Mute or unmute the sound"
        onPressed: Audio.toggleMute()
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "micMute"
        description: "Mute or unmute the microphone"
        onPressed: Audio.toggleMicMute()
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "brightnessUp"
        description: "Raise the brightness"
        onPressed: Brightness.change(0.05)
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "brightnessDown"
        description: "Lower the brightness"
        onPressed: Brightness.change(-0.05)
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "mediaToggle"
        description: "Play or pause"
        onPressed: Media.togglePlaying()
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "mediaNext"
        description: "Next track"
        onPressed: Media.next()
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "mediaPrevious"
        description: "Previous track"
        onPressed: Media.previous()
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "nightLight"
        description: "Turn Night Light on or off"
        onPressed: NightLight.setEnabled(!NightLight.enabled)
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "keepAwake"
        description: "Turn Keep Awake on or off"
        onPressed: KeepAwake.toggle()
    }

    GlobalShortcut {
        appid: "ezshell"
        name: "wallpaperNext"
        description: "Change to the next wallpaper"
        onPressed: Wallpapers.next()
    }
}
