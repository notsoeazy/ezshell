pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The media player worth showing: one that is playing, else the first.
Singleton {
    id: root

    readonly property list<MprisPlayer> players: Mpris.players.values
    readonly property MprisPlayer player: players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property bool available: player !== null
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string artUrl: player?.trackArtUrl ?? ""
    // The player's own name ("Spotify").
    readonly property string source: player?.identity ?? ""
    // Seconds. The player does not announce its position as it plays, so while
    // something shows it (`watching`) it is asked once a second.
    readonly property real position: player?.position ?? 0
    readonly property real length: player?.length ?? 0
    // Whether the player's position and length can be believed: both
    // supported, a length above zero, and the position not past its end.
    // Browsers playing video often fail this.
    readonly property bool hasProgress: (player?.positionSupported ?? false) && (player?.lengthSupported ?? false) && length > 0 && position <= length + 1
    readonly property bool canSeek: hasProgress && (player?.canSeek ?? false)
    property bool watching

    function seek(seconds: real): void {
        if (canSeek)
            player.position = Math.max(0, Math.min(length, seconds));
    }

    function togglePlaying(): void {
        if (player?.canTogglePlaying)
            player.togglePlaying();
    }

    function next(): void {
        if (player?.canGoNext)
            player.next();
    }

    function previous(): void {
        if (player?.canGoPrevious)
            player.previous();
    }

    Timer {
        running: root.watching && root.playing
        repeat: true
        interval: 1000
        onTriggered: root.player.positionChanged()
    }
}
