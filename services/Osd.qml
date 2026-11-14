pragma Singleton

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.utils

// What the on-screen display is showing: a level (volume, brightness) or a
// short message. This is the one place that decides which changes in other
// services are worth showing. It knows nothing about the island; the island
// shows whatever is active here and tells it when to hold back.
Singleton {
    id: root

    // "level" or "toast"; empty when nothing is showing.
    property string kind
    property string icon
    property string text
    // What a level belongs to ("volume", "brightness"), so the display can
    // change it; empty for a level that is only shown.
    property string source
    // 0..1
    property real value
    readonly property bool active: kind.length > 0

    // Set by the island. While blocked (a panel or sheet is open) levels are
    // dropped, since the panel already shows them, and a message waits.
    property bool blocked
    // Set by the island while the pointer is on the display: it stays up.
    property bool held

    // A message that arrived while blocked, and when.
    property var waiting: null
    // Services report their first values just after startup; those are not
    // changes, so nothing is shown until things have settled.
    property bool armed

    function level(source: string, icon: string, value: real): void {
        if (!Config.osd.enabled || blocked)
            return;

        // A level that belongs to something can be turned off by its name
        // (`osd.show.volume`); one shown over IPC has no source and always shows.
        if (source.length > 0 && Config.osd.show[source] === false)
            return;

        root.source = source;
        root.icon = icon;
        root.value = Math.max(0, Math.min(1, value));
        root.text = "";
        show("level", Config.osd.levelTimeout);
    }

    // A message that can be turned off in the config, by `kind` (a name in
    // `osd.show`). `inPanel` is for things the control panel also shows: while
    // the panel or a sheet is open they are dropped, not held for later.
    function announce(kind: string, icon: string, message: string, inPanel: bool): void {
        if (Config.osd.show[kind] === false || (inPanel && blocked))
            return;

        toast(icon, message);
    }

    function toast(icon: string, message: string): void {
        if (!Config.osd.enabled)
            return;

        if (blocked) {
            waiting = {
                icon: icon,
                message: message,
                at: Date.now()
            };
            return;
        }
        root.source = "";
        root.icon = icon;
        root.text = message;
        show("toast", Config.osd.toastTimeout);
    }

    function show(kind: string, timeout: int): void {
        root.kind = kind;
        hide.interval = timeout;
        hide.restart();
    }

    function dismiss(): void {
        hide.stop();
        kind = "";
    }

    // Change the thing a level belongs to, from the display itself.
    function adjust(value: real): void {
        if (source === "volume")
            Audio.setVolume(value);
        else if (source === "brightness")
            Brightness.set(value);
    }

    onBlockedChanged: {
        if (blocked) {
            dismiss();
        } else if (waiting !== null) {
            // Show a message that waited, unless it has gone stale.
            const message = waiting;
            waiting = null;
            if (Date.now() - message.at < Config.osd.toastTimeout)
                toast(message.icon, message.message);
        }
    }

    onHeldChanged: {
        if (!held && active)
            hide.restart();
    }

    Timer {
        id: hide

        onTriggered: {
            if (!root.held)
                root.kind = "";
        }
    }

    Timer {
        running: true
        interval: 2000
        onTriggered: root.armed = true
    }

    Connections {
        function onVolumeChanged(): void {
            if (root.armed)
                root.level("volume", Audio.muted ? "volume_off" : Symbols.level("speaker", Audio.volume), Audio.volume);
        }

        function onMutedChanged(): void {
            if (root.armed)
                root.level("volume", Audio.muted ? "volume_off" : Symbols.level("speaker", Audio.volume), Audio.volume);
        }

        function onMicMutedChanged(): void {
            if (root.armed)
                root.announce("microphone", Audio.micMuted ? "mic_off" : "mic", Audio.micMuted ? "Microphone muted" : "Microphone on", false);
        }

        target: Audio
    }

    Connections {
        function onValueChanged(): void {
            if (root.armed)
                root.level("brightness", Symbols.level("brightness", Brightness.value), Brightness.value);
        }

        target: Brightness
    }

    Connections {
        function onDoNotDisturbChanged(): void {
            if (root.armed)
                root.announce("doNotDisturb", ShellState.doNotDisturb ? "notifications_off" : "notifications", ShellState.doNotDisturb ? "Do Not Disturb on" : "Do Not Disturb off", false);
        }

        target: ShellState
    }

    Connections {
        function onEnabledChanged(): void {
            if (root.armed)
                root.announce("nightLight", "bedtime", NightLight.enabled ? "Night Light on" : "Night Light off", true);
        }

        target: NightLight
    }

    Connections {
        function onEnabledChanged(): void {
            if (root.armed)
                root.announce("keepAwake", "coffee", KeepAwake.enabled ? "Keep Awake on" : "Keep Awake off", true);
        }

        target: KeepAwake
    }
}
