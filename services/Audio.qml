pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.config

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool ready: (root.sink?.ready ?? false) && root.sink.audio !== null
    readonly property bool micReady: (root.source?.ready ?? false) && root.source.audio !== null
    readonly property real volume: root.sink?.audio?.volume ?? 0
    readonly property bool muted: root.sink?.audio?.muted ?? false
    readonly property real micVolume: root.source?.audio?.volume ?? 0
    readonly property bool micMuted: root.source?.audio?.muted ?? false
    readonly property list<PwNode> outputs: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property list<PwNode> inputs: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)
    // App playback streams: Quickshell reports them as isSink (verified with pw-play). Capture streams
    // aren't controlled here. Their properties stay empty until the tracker below binds them.
    readonly property list<PwNode> streams: Pipewire.nodes.values.filter(n => n.isStream && n.isSink)
    // Links from a microphone (an audio source device, not an output's monitor) into an app's stream.
    readonly property list<PwLinkGroup> micLinks: Pipewire.linkGroups.values.filter(root.isMicCapture)
    readonly property bool micCapturing: root.micLinks.length > 0
    // After Config.indicators.delay of continuous capture; see the timer below.
    readonly property bool micInUse: root.micCapturing && micDelay.passed
    readonly property list<string> micApps: [...new Set(root.micLinks.map(g => root.label(g.target)))]

    function set(volume: real): void {
        if (!root.sink?.audio)
            return;
        root.sink.audio.muted = false;
        // Rounded to whole percent so repeated steps don't drift (0.8 + 0.05 + 0.05 ...).
        root.sink.audio.volume = Math.round(Math.max(0, Math.min(1, volume)) * 100) / 100;
    }

    function setMicVolume(volume: real): void {
        if (root.source?.audio)
            root.source.audio.volume = Math.round(Math.max(0, Math.min(1, volume)) * 100) / 100;
    }

    function up(): void {
        root.set(root.volume + Config.audio.step);
    }

    function down(): void {
        root.set(root.volume - Config.audio.step);
    }

    function toggleMute(): void {
        if (root.sink?.audio)
            root.sink.audio.muted = !root.muted;
    }

    function toggleMicMute(): void {
        if (root.source?.audio)
            root.source.audio.muted = !root.micMuted;
    }

    // Human-readable name: the device description, or the app name for a stream.
    function isMicCapture(link: PwLinkGroup): bool {
        return link.source?.type === PwNodeType.AudioSource && (link.target?.isStream ?? false);
    }

    function micStatus(): string {
        return root.micInUse ? `in use by ${root.micApps.join(", ")}` : "not in use";
    }

    function label(node: PwNode): string {
        if (node?.isStream)
            return node.properties["application.name"] ?? node.name;
        return node?.description || node?.nickname || node?.name || "";
    }

    function setOutput(name: string): void {
        const node = root.outputs.find(n => n.name === name);
        if (node)
            Pipewire.preferredDefaultAudioSink = node;
    }

    function setInput(name: string): void {
        const node = root.inputs.find(n => n.name === name);
        if (node)
            Pipewire.preferredDefaultAudioSource = node;
    }

    function setStreamVolume(id: int, volume: real): void {
        const node = root.streams.find(n => n.id === id);
        if (node?.audio)
            node.audio.volume = Math.max(0, Math.min(1, volume));
    }

    function toggleStreamMute(id: int): void {
        const node = root.streams.find(n => n.id === id);
        if (node?.audio)
            node.audio.muted = !node.audio.muted;
    }

    function describe(nodes: list<PwNode>, current: PwNode): string {
        return nodes.map(n => `${n === current ? "*" : " "} ${n.name}  (${root.label(n)})`).join("\n");
    }

    function describeStream(node: PwNode): string {
        const volume = `${Math.round((node.audio?.volume ?? 0) * 100)}%${node.audio?.muted ? " muted" : ""}`;
        return `${node.id} ${volume} ${root.label(node)}`;
    }

    function status(): string {
        const out = `${Math.round(root.volume * 100)}%${root.muted ? " muted" : ""}`;
        const mic = `${Math.round(root.micVolume * 100)}%${root.micMuted ? " muted" : ""}`;
        return `out ${out}, mic ${mic}`;
    }

    onMicCapturingChanged: {
        if (!root.micCapturing)
            micDelay.passed = false;
    }

    // Without tracking, a node's audio properties stay invalid.
    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    PwObjectTracker {
        objects: root.streams
    }

    Timer {
        id: micDelay

        property bool passed: false

        interval: Config.indicators.delay
        running: root.micCapturing && !micDelay.passed
        onTriggered: micDelay.passed = true
    }

    // Binds the capturing apps' streams, so their application.name is known for micApps.
    PwObjectTracker {
        objects: root.micLinks.map(g => g.target)
    }

    IpcHandler {
        function up(): void {
            root.up();
        }

        function down(): void {
            root.down();
        }

        function set(volume: real): void {
            root.set(volume);
        }

        function toggleMute(): void {
            root.toggleMute();
        }

        function toggleMicMute(): void {
            root.toggleMicMute();
        }

        function mic(): string {
            return root.micStatus();
        }

        function setMic(volume: real): void {
            root.setMicVolume(volume);
        }

        function status(): string {
            return root.status();
        }

        function outputs(): string {
            return root.describe(root.outputs, root.sink);
        }

        function inputs(): string {
            return root.describe(root.inputs, root.source);
        }

        function streams(): string {
            return root.streams.map(root.describeStream).join("\n");
        }

        function setOutput(name: string): void {
            root.setOutput(name);
        }

        function setInput(name: string): void {
            root.setInput(name);
        }

        function setStreamVolume(id: int, volume: real): void {
            root.setStreamVolume(id, volume);
        }

        target: "audio"
    }
}
