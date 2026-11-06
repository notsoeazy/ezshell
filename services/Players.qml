pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property list<MprisPlayer> players: Mpris.players.values
    // The playing player wins; otherwise the first one that can be controlled.
    readonly property MprisPlayer controllable: root.players.find(p => p.canControl) ?? null
    // A player picked in the media tab wins while it exists; otherwise the playing one.
    readonly property MprisPlayer picked: root.players.includes(internal.picked) ? internal.picked : null
    readonly property MprisPlayer active: root.picked ?? root.players.find(p => p.isPlaying) ?? root.controllable
    readonly property bool playing: root.active?.isPlaying ?? false
    readonly property string title: root.active?.trackTitle ?? ""
    readonly property string artist: root.active?.trackArtist ?? ""
    readonly property string artUrl: root.active?.trackArtUrl ?? ""
    readonly property string identity: root.active?.identity ?? ""
    // Seconds. MPRIS doesn't notify position changes; the timer below refreshes it while `tracking`.
    readonly property real position: root.active?.position ?? 0
    readonly property real length: root.active?.length ?? 0
    readonly property bool canSeek: root.active?.canSeek ?? false
    // Set by the UI while a progress bar is visible.
    property bool tracking: false
    // Most saturated album-art color, for tinting; hasAccent is false until the art has been quantized.
    readonly property bool hasAccent: root.artUrl !== "" && quantizer.colors.length > 0
    readonly property color accent: root.pickAccent(quantizer.colors)

    function pickAccent(colors: list<color>): color {
        // Weighted by value so near-black colors, invisible on the black island, lose.
        const score = c => c.hsvSaturation * c.hsvValue;
        return [...colors].sort((a, b) => score(b) - score(a))[0] ?? "transparent";
    }

    function select(identity: string): void {
        internal.picked = root.players.find(p => p.identity === identity) ?? null;
    }

    function seek(seconds: real): void {
        if (root.canSeek)
            root.active.position = Math.max(0, Math.min(root.length, seconds));
    }

    function playPause(): void {
        if (root.active?.canTogglePlaying)
            root.active.togglePlaying();
    }

    function next(): void {
        if (root.active?.canGoNext)
            root.active.next();
    }

    function previous(): void {
        if (root.active?.canGoPrevious)
            root.active.previous();
    }

    function status(): string {
        if (!root.active)
            return "no player";
        const state = root.playing ? "playing" : "paused";
        return `${root.active.identity}: ${state} "${root.title}" by ${root.artist}`;
    }

    QtObject {
        id: internal

        property MprisPlayer picked: null
    }

    // MPRIS position doesn't notify; poke it once a second, only while playing and shown.
    Timer {
        interval: 1000
        running: root.tracking && root.playing
        repeat: true
        onTriggered: root.active?.positionChanged()
    }

    // Quantizes once per track: the source only changes with the art URL.
    ColorQuantizer {
        id: quantizer

        source: root.artUrl
        depth: 3
        rescaleSize: 64
    }

    IpcHandler {
        function playPause(): void {
            root.playPause();
        }

        function next(): void {
            root.next();
        }

        function previous(): void {
            root.previous();
        }

        function status(): string {
            return root.status();
        }

        function list(): string {
            return root.players.map(p => `${p === root.active ? "*" : " "} ${p.identity}`).join("\n");
        }

        function select(identity: string): void {
            root.select(identity);
        }

        function seek(seconds: real): void {
            root.seek(seconds);
        }

        function position(): string {
            return `${Math.round(root.position)}s / ${Math.round(root.length)}s`;
        }

        target: "players"
    }
}
