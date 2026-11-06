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
            root.show("mic", Config.osd.hideDelay);
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

    // UI-only timer: it ends a UI mode, so it lives with the island rather than in a service.
    Timer {
        id: hideTimer

        onTriggered: Visibility.temporary = ""
    }
}
