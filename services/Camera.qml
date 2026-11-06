pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.config
import qs.services

// Camera in use, from two sources: PipeWire links from a camera device (v4l2/libcamera) into an app's
// stream (names the app), and open/close events on /dev/video* (scripts/camera-watch.sh) for apps that
// open the camera directly, as most browsers do. Event-driven; nothing is polled.
Singleton {
    id: root

    readonly property list<PwLinkGroup> links: Pipewire.linkGroups.values.filter(root.isCameraCapture)
    readonly property bool capturing: root.links.length > 0 || internal.openDevices > 0
    // After Config.indicators.delay of continuous use, which also hides PipeWire's short device probes.
    readonly property bool inUse: root.capturing && delay.passed
    // PipeWire names the app; a direct /dev/video open doesn't.
    readonly property list<string> pipewireApps: [...new Set(root.links.map(g => Audio.label(g.target)))]
    readonly property list<string> apps: root.pipewireApps.length > 0 ? root.pipewireApps : ["an app"]

    // Screen shares are video sources too (xdg-desktop-portal-hyprland), so the node name decides.
    function isCameraCapture(link: PwLinkGroup): bool {
        const camera = link.source?.type === PwNodeType.VideoSource && /^(v4l2|libcamera)/.test(link.source.name);
        return camera && (link.target?.isStream ?? false);
    }

    // "OPEN /dev/video0" or "CLOSE_NOWRITE,CLOSE /dev/video0"; never below zero if the shell started
    // while a device was already open.
    function onDeviceEvent(line: string): void {
        const opened = line.startsWith("OPEN");
        internal.openDevices = Math.max(0, internal.openDevices + (opened ? 1 : -1));
    }

    function status(): string {
        if (!root.inUse)
            return root.capturing ? "starting" : "not in use";
        return `in use by ${root.apps.join(", ")}`;
    }

    onCapturingChanged: {
        if (!root.capturing)
            delay.passed = false;
    }

    QtObject {
        id: internal

        property int openDevices: 0
    }

    Timer {
        id: delay

        property bool passed: false

        interval: Config.indicators.delay
        running: root.capturing && !delay.passed
        onTriggered: delay.passed = true
    }

    Process {
        running: true
        command: ["sh", Quickshell.shellPath("scripts/camera-watch.sh")]
        stdout: SplitParser {
            onRead: line => root.onDeviceEvent(line)
        }
    }

    // Binds the apps' streams, so their application.name is known.
    PwObjectTracker {
        objects: root.links.map(g => g.target)
    }

    IpcHandler {
        function status(): string {
            return root.status();
        }

        target: "camera"
    }
}
