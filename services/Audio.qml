pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default output and input: volume and mute.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool ready: sink?.ready ?? false

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false
    // Whether an application is recording from the default input.
    readonly property bool micInUse: micLinks.linkGroups.some(g => g.source?.isStream || g.target?.isStream)

    // Real devices only, not application streams.
    readonly property list<PwNode> devices: Pipewire.nodes.values.filter(n => !n.isStream && n.audio)
    readonly property list<PwNode> sinks: devices.filter(n => n.isSink)
    readonly property list<PwNode> sources: devices.filter(n => !n.isSink)

    // Applications playing sound.
    readonly property list<PwNode> streams: Pipewire.nodes.values.filter(n => n.isStream && n.isSink && n.audio)

    // An application's name, and what it is playing.
    function streamLabel(node: PwNode): string {
        return node.properties["application.name"] || node.description || node.name;
    }

    function streamDetail(node: PwNode): string {
        return node.properties["media.name"] ?? "";
    }

    // Volume and mute for any device or application.
    function setNodeVolume(node: PwNode, value: real): void {
        if (node?.ready && node.audio)
            node.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleNodeMute(node: PwNode): void {
        if (node?.ready && node.audio)
            node.audio.muted = !node.audio.muted;
    }

    function label(node: PwNode): string {
        return node.description || node.nickname || node.name;
    }

    function setSink(node: PwNode): void {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setSource(node: PwNode): void {
        Pipewire.preferredDefaultAudioSource = node;
    }

    function changeVolume(delta: real): void {
        setVolume(volume + delta);
    }

    function setVolume(value: real): void {
        if (sink?.ready && sink.audio)
            sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    function setMicVolume(value: real): void {
        if (source?.ready && source.audio)
            source.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleMute(): void {
        if (sink?.ready && sink.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleMicMute(): void {
        if (source?.ready && source.audio)
            source.audio.muted = !source.audio.muted;
    }

    // The connections to the default input: one to each application using it.
    PwNodeLinkTracker {
        id: micLinks

        node: root.source
    }

    // PipeWire only reports a node's properties while something tracks it.
    PwObjectTracker {
        objects: [root.sink, root.source, ...root.streams]
    }
}
