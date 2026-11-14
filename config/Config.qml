pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// User preferences, persisted as JSON. Every option has a default here, so the
// shell starts without a config file; the file is only written once a setting
// is changed from QML.
Singleton {
    id: root

    readonly property string path: `${Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`}/ezshell/config.json`
    readonly property alias appearance: adapter.appearance
    readonly property alias border: adapter.border
    readonly property alias island: adapter.island
    readonly property alias osd: adapter.osd
    readonly property alias notifications: adapter.notifications
    readonly property alias launcher: adapter.launcher
    readonly property alias wallpaper: adapter.wallpaper
    readonly property alias session: adapter.session
    readonly property alias idle: adapter.idle
    readonly property alias capture: adapter.capture
    readonly property alias theming: adapter.theming

    FileView {
        path: root.path
        printErrors: false
        watchChanges: true

        // Block until the first load finishes so nothing renders with defaults
        // and then jumps. The file is small and this runs once, at startup.
        Component.onCompleted: waitForJob()
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter

            property Appearance appearance: Appearance {}
            property Border border: Border {}
            property Island island: Island {}
            property Osd osd: Osd {}
            property Notifications notifications: Notifications {}
            property Launcher launcher: Launcher {}
            property Wallpaper wallpaper: Wallpaper {}
            property Session session: Session {}
            property Idle idle: Idle {}
            property Capture capture: Capture {}
            property Theming theming: Theming {}
        }
    }

    // The sections. Each is its own type, so that its options are typed for the
    // linter and language server.

    // The "appearance" section of the config file.
    component Appearance: JsonObject {
        property bool dark: false
        // Name of a system colour in ColorScheme.
        property string accent: "blue"
        // Multiplies every animation duration; 2 is half speed.
        property real animationScale: 1
        property bool reduceMotion: false
    }

    // The "border" section of the config file: the frame around every screen.
    component Border: JsonObject {
        // Width of the frame, in pixels. 0 turns it off. The island hangs from
        // its inner top edge.
        property real thickness: 5
        // Radius of the frame's inner corners, in pixels.
        property real rounding: 22
    }

    // The "island" section of the config file.
    component Island: JsonObject {
        property bool enabled: true
        // Name of the monitor that hosts the island (e.g. "eDP-1"); empty means
        // the first one.
        property string monitor: ""
        // Space kept clear of windows between the island and the windows
        // below it, in pixels. The strip is always reserved.
        property real reserveGap: 4
        // Shrink to the clock (`idle`) when nothing is happening. Off keeps
        // the island in `default` all the time.
        property bool idleView: true
        // How long the island stays in `default` after an event before it
        // shrinks to the clock, in ms. Only matters while `idleView` is on.
        property int pulseDuration: 3000
        // Hover must last this long before `hovered` opens, and the pointer must
        // be gone this long before it closes, in ms.
        property int hoverEnterDelay: 80
        property int hoverExitDelay: 300
        property string clockFormat: "hh:mm"
        // Show the distribution's logo in `default`.
        property bool showLogo: true
        // The notifications section of `hovered`: "always" shows it, with a
        // "All caught up!" card when there are none; "whenAny" shows it only
        // while there are notifications, as the media controls do; "never"
        // leaves it out.
        property string hoveredNotifications: "always"
        // The logo: an icon theme name or a file path (`~` works). Empty uses
        // the distribution's own, from /etc/os-release.
        property string logo: ""
        // Workspaces in a page. The island shows the page of the focused
        // workspace (1 to 10, 11 to 20, ...) and never more. Keep it equal to
        // the page size in your Hyprland workspace binds.
        property int workspaces: 10
        // Icons for special workspaces, by name; one not listed gets a default.
        property var specialIcons: ({
                "music": "music_note",
                "communication": "forum",
                "sysmon": "monitor_heart",
                "todo": "checklist",
                "special": "star"
            })
        // Events that make the island show `default` for a moment.
        property list<string> pulseOn: ["workspace", "special", "volume", "mic", "network", "battery", "media", "notification"]
    }

    // Which things may raise the on-screen display. `osd.enabled` turns the
    // whole display off; each of these turns off one kind of message.
    component OsdMessages: JsonObject {
        // The level bars.
        property bool volume: true
        property bool brightness: true
        // Messages.
        property bool microphone: true
        property bool doNotDisturb: true
        property bool nightLight: true
        property bool keepAwake: true
        // A screenshot or recording was saved. Failures always show.
        property bool capture: true
    }

    // The "osd" section of the config file.
    component Osd: JsonObject {
        property bool enabled: true
        property OsdMessages show: OsdMessages {}
        // How long a level (volume, brightness) stays up, in ms.
        property int levelTimeout: 1500
        // How long a message stays up, in ms.
        property int toastTimeout: 2500
    }

    // The "notifications" section of the config file.
    component Notifications: JsonObject {
        // How long a new notification is shown on the island, in ms.
        property int bannerTimeout: 5000
        // Lines of a notification's body shown when it is expanded; collapsed
        // it is one line.
        property int bodyLines: 8
        // Start every notification expanded.
        property bool openExpanded: false
        // How far a notification has to be dragged sideways to dismiss it, as
        // a part of its width.
        property real dismissThreshold: 0.4
        // How far (in pixels) a drag down or up has to go to open or close a
        // notification.
        property int expandThreshold: 20
        // How many notifications are kept (and saved for the next start).
        property int keep: 100
    }

    // The "launcher" section of the config file.
    component Launcher: JsonObject {
        // What a search must start with to switch mode.
        property string actionsPrefix: ">"
        property string clipboardPrefix: ":"
        property string symbolsPrefix: "."
        // How many results to show at most.
        property int maxResults: 50
    }

    // The "wallpaper" section of the config file.
    component Wallpaper: JsonObject {
        // Whether the shell draws the wallpaper itself.
        property bool enabled: true
        // Folder searched (three levels deep) for pictures. "~" is your home.
        property string directory: "~/Pictures/Wallpapers"
    }

    // The "session" section of the config file.
    component Session: JsonObject {
        // Command run to lock the screen, in place of the shell's own lock
        // screen. Empty (the default) uses the shell's.
        property list<string> lockCommand: []
    }

    // The "idle" section of the config file: what happens when the computer is
    // left alone. Every time is in seconds, and 0 turns that step off.
    component Idle: JsonObject {
        // Lock the screen after this long without input.
        property int lockAfter: 300
        // Turn the screens off after this long.
        property int screenOffAfter: 360
        // Suspend after this long.
        property int suspendAfter: 0
        // Lock before the computer goes to sleep, so it wakes up locked.
        property bool lockBeforeSleep: true
        // Lock when the system asks (`loginctl lock-session`).
        property bool lockOnRequest: true
        // How long sleep is held back for the lock screen to come up, in ms.
        property int sleepGrace: 600
    }

    // The "capture" section of the config file: screenshots and recordings.
    component Capture: JsonObject {
        // What a screenshot does when no action is named: "edit" opens it in the
        // editor, "copy" copies it, "save" saves and copies it.
        property string screenshotAction: "edit"
        // The editor a screenshot opens in; the file's path is added at the end.
        property list<string> editor: ["swappy", "-f"]
        // ~ is your home.
        property string screenshotDirectory: "~/Pictures/Screenshots"
        property string recordingDirectory: "~/Videos/Recordings"
        // How the record button starts: "screen", "sound" (the screen with
        // sound) or "region".
        property string recordMode: "screen"
        // Record the microphone as well, in the mode with sound.
        property bool recordMicrophone: false
        property int recordFps: 60
    }

    // The "theming" section of the config file: colours made from the wallpaper.
    component Theming: JsonObject {
        // Take the shell's colours from the wallpaper. Off uses the fixed
        // palette and the accent chosen in Appearance.
        property bool dynamic: true
        // How colourful the palette is: one of matugen's scheme types, without
        // the "scheme-" (tonal-spot, vibrant, expressive, neutral, content,
        // fidelity, fruit-salad, rainbow, monochrome).
        property string variant: "tonal-spot"
        // Colour other programs too. Each of these writes outside the shell:
        // open terminals; ~/.config/hypr/scheme/current.lua; ~/.config/gtk-3.0
        // and gtk-4.0/gtk.css; and each file in ~/.config/ezshell/templates,
        // filled in and written to the theme folder in the shell's state.
        property bool terminal: false
        property bool hyprland: false
        property bool gtk: false
        property bool templates: true
    }
}
