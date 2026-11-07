import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.config
import qs.services
import qs.state

// Turns service changes into short-lived island modes. Services don't know the island exists.
Scope {
    id: root

    // Last seen values, "" while a service isn't ready, so startup isn't mistaken for a change.
    property string lastAudio: ""
    property string lastBrightness: ""
    property string lastMic: ""
    property string lastTrack: ""
    readonly property string audioState: Audio.ready ? `${Audio.volume} ${Audio.muted}` : ""
    readonly property string brightnessState: Brightness.ready ? `${Brightness.level}` : ""
    readonly property string micState: Audio.micReady ? `${Audio.micMuted}` : ""
    readonly property string trackState: Players.playing ? Players.title : ""
    readonly property bool fullscreen: Hypr.fullscreen(Hypr.focusedScreen)
    readonly property var captureMessages: ({
            selecting: {
                source: "capture",
                icon: "screenshot_region",
                tone: "primary",
                text: "Drag to select",
                hint: "Esc to cancel"
            },
            starting: {
                source: "capture",
                dot: "pulse",
                text: "Starting recording…"
            },
            recording: {
                source: "capture",
                dot: "steady",
                text: "Recording",
                hint: "click the red indicator to stop"
            }
        })

    // 75 → "1:15".
    function clock(seconds: int): string {
        return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")}`;
    }

    // duration 0 keeps the mode until something else replaces or closes it.
    function show(mode: string, duration: int): void {
        Visibility.temporary = mode;
        hideTimer.interval = duration;
        if (duration > 0)
            hideTimer.restart();
        else
            hideTimer.stop();
    }

    // Skipped while expanded (the notification still lands in the list), under DND unless critical,
    // and over fullscreen unless the user allows it.
    function notify(notification: Notification): void {
        // Capture's own notification: the island has just shown the capture, so it only goes to the list.
        if (notification.hints["x-ezshell-capture"])
            return;
        const critical = notification.urgency === NotificationUrgency.Critical;
        if (Visibility.expanded || (Notifs.dnd && !critical))
            return;
        if (root.fullscreen && !Config.notifications.showInFullscreen)
            return;
        root.show("notification", critical ? 0 : Config.notifications.timeout);
    }

    onAudioStateChanged: {
        if (root.lastAudio !== "" && root.audioState !== "")
            root.show("volume", Config.osd.hideDelay);
        root.lastAudio = root.audioState;
    }
    onBrightnessStateChanged: {
        if (root.lastBrightness !== "" && root.brightnessState !== "")
            root.show("brightness", Config.osd.hideDelay);
        root.lastBrightness = root.brightnessState;
    }
    onMicStateChanged: {
        if (root.lastMic !== "" && root.micState !== "")
            Visibility.say({
                icon: Audio.micMuted ? "mic_off" : "mic",
                tone: Audio.micMuted ? "error" : "normal",
                text: Audio.micMuted ? "Microphone muted" : "Microphone on"
            }, Config.osd.hideDelay);
        root.lastMic = root.micState;
    }
    // A new track while playing shows the compact pill, unless a banner is up or a game is fullscreen.
    onTrackStateChanged: {
        const banner = Visibility.temporary === "notification";
        if (root.lastTrack !== root.trackState && root.trackState !== "" && !banner && !root.fullscreen)
            root.show("music", Config.osd.hideDelay);
        root.lastTrack = root.trackState;
    }
    Component.onCompleted: {
        root.lastAudio = root.audioState;
        root.lastBrightness = root.brightnessState;
        root.lastMic = root.micState;
        root.lastTrack = root.trackState;
    }

    Connections {
        function onReceived(notification: Notification): void {
            root.notify(notification);
        }

        // The banner closes with its notification (dismissed, expired or activated).
        function onLatestChanged(): void {
            if (!Notifs.latest && Visibility.temporary === "notification")
                Visibility.temporary = "";
        }

        target: Notifs
    }

    // Every say() (here, from a service event, or `osd say` over IPC) becomes the message mode.
    Connections {
        function onMessageRequestChanged(): void {
            root.show("message", Visibility.messageDuration);
        }

        target: Visibility
    }

    Connections {
        function onRecorded(path: string, seconds: int): void {
            Visibility.say({
                icon: "check_circle",
                tone: "success",
                text: "Recording saved",
                subtitle: `${path.split("/").pop()} · ${root.clock(seconds)}`
            }, Config.osd.hideDelay);
        }

        function onFailed(what: string, reason: string): void {
            Visibility.say({
                icon: "error",
                tone: "error",
                text: what === "recording" ? "Recording failed" : "Screenshot failed",
                subtitle: reason
            }, Config.osd.hideDelay);
        }

        function onShotTaken(path: string): void {
            Visibility.say({
                thumbnail: path,
                text: "Screenshot",
                subtitle: "Saved · Copied"
            }, Config.osd.hideDelay);
        }

        // Selecting and starting stay up until they end; "recording" is said once, then the indicator stays.
        // The source tag lets the end of a capture clear only its own message.
        function onPhaseChanged(): void {
            const phase = Capture.phase;
            if (phase !== "")
                Visibility.say(root.captureMessages[phase], phase === "recording" ? Config.osd.hideDelay : 0);
            else if (Visibility.temporary === "message" && Visibility.message.source === "capture")
                Visibility.temporary = "";
        }

        target: Capture
    }

    // UI-only timer: it ends a UI mode, so it lives with the island rather than in a service.
    Timer {
        id: hideTimer

        onTriggered: Visibility.temporary = ""
    }
}
