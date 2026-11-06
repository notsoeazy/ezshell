pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

// Screenshots (grim, slurp for regions) and screen recording (gpu-screen-recorder). Every capture process
// lives here. Paths and geometry go to `sh -c` as arguments, never spliced into the script.
// gpu-screen-recorder reads the GPU directly, so Hyprland reports no screencast: `recording` is what the
// island's indicator follows. SIGINT stops it with a finished, playable file.
Singleton {
    id: root

    readonly property list<string> modes: ["region", "window", "monitor", "full"]
    readonly property var actionLabels: ({
            open: "Open",
            folder: "Open folder",
            edit: "Edit"
        })
    readonly property string screenshotDir: Paths.expand(Config.capture.screenshots)
    readonly property string recordingDir: Paths.expand(Config.capture.recordings)
    // Picking a region or a window, or writing a screenshot.
    readonly property bool busy: selector.running || locator.running || shooter.running
    readonly property bool recording: recorder.running
    // What the island shows while a capture is under way: selecting (slurp is up), starting (the recorder
    // is setting up its encoder, 1-2 s) or recording (frames are being written); "" otherwise.
    readonly property string phase: selector.running ? "selecting" : root.recordingPhase()
    // Milliseconds between the end of a selection and the screenshot, so on-screen hints (the island's
    // "Drag to select") have cleared. The island sets it from its own collapse time.
    property int settle: 0
    readonly property string recordingFile: internal.recordingFile
    readonly property string lastShot: internal.lastShot
    // satty or swappy for the notification's Edit, "" when neither is installed.
    readonly property string editor: internal.editor

    signal shotTaken(string path)

    function recordingPhase(): string {
        if (!root.recording)
            return "";
        return internal.capturing ? "recording" : "starting";
    }

    function stamp(): string {
        return Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss");
    }

    function screenshot(mode: string): void {
        if (!root.modes.includes(mode)) {
            console.warn(`[capture] unknown mode ${mode}; use ${root.modes.join(", ")}`);
            return;
        }
        if (root.busy)
            return;
        internal.purpose = "shot";
        if (mode === "region")
            selector.exec(["slurp"]);
        else if (mode === "window")
            locator.exec(["hyprctl", "-j", "activewindow"]);
        else
            root.shoot(mode === "monitor" ? ["-o", Hypr.focusedScreen] : []);
    }

    // region, window or monitor (one output; gpu-screen-recorder has no "all outputs").
    function record(mode: string): void {
        if (!["region", "window", "monitor"].includes(mode)) {
            console.warn(`[capture] can't record ${mode}; use region, window or monitor`);
            return;
        }
        if (root.recording || root.busy)
            return;
        internal.purpose = "record";
        if (mode === "region")
            selector.exec(["slurp", "-f", "%wx%h+%x+%y"]);
        else if (mode === "window")
            locator.exec(["hyprctl", "-j", "activewindow"]);
        else
            root.startRecording(["-w", Hypr.focusedScreen]);
    }

    function stop(): void {
        if (root.recording)
            recorder.signal(2);
    }

    function toggle(mode: string): void {
        if (root.recording)
            root.stop();
        else
            root.record(mode);
    }

    function setAudio(enabled: bool): void {
        Config.capture.audio = enabled;
    }

    // At the focused monitor's refresh rate, with the default output's sound when audio is on.
    function startRecording(source: list<string>): void {
        const rate = Math.round(Hypr.monitor(Hypr.focusedScreen)?.lastIpcObject.refreshRate ?? 60);
        const audio = Config.capture.audio ? ["-a", "default_output"] : [];
        internal.recordingFile = `${root.recordingDir}/recording_${root.stamp()}.mp4`;
        const args = [...source, "-f", `${rate}`, ...audio, "-o", internal.recordingFile];
        // exec, so the Process's pid is the recorder's and stop()'s SIGINT reaches it.
        const script = 'mkdir -p "$1" && shift && exec gpu-screen-recorder "$@"';
        recorder.exec(["sh", "-c", script, "sh", root.recordingDir, ...args]);
    }

    // The same after a pause, so a launcher or panel can collapse first and stay out of the shot.
    function screenshotIn(mode: string, ms: int): void {
        root.later("shot", mode, ms);
    }

    function recordIn(mode: string, ms: int): void {
        root.later("record", mode, ms);
    }

    function later(purpose: string, mode: string, ms: int): void {
        internal.delayedPurpose = purpose;
        internal.delayedMode = mode;
        delay.interval = Math.max(0, ms);
        delay.restart();
    }

    // grim with these arguments, saved under a timestamped name and copied as an image.
    function shoot(args: list<string>): void {
        internal.pending = `${root.screenshotDir}/screenshot_${root.stamp()}.png`;
        const copy = 'wl-copy --type image/png < "$file"';
        const script = `dir=$1 file=$2; shift 2; mkdir -p "$dir" && grim "$@" "$file" && ${copy}`;
        shooter.exec(["sh", "-c", script, "sh", root.screenshotDir, internal.pending, ...args]);
    }

    // hyprctl -j activewindow: { at: [x, y], size: [w, h] } in layout coordinates, as grim and
    // gpu-screen-recorder take them; null without an active window.
    function windowBox(json: string): var {
        try {
            const window = JSON.parse(json);
            if (!window.at || !window.size)
                return null;
            return {
                x: window.at[0],
                y: window.at[1],
                w: window.size[0],
                h: window.size[1]
            };
        } catch (e) {
            return null;
        }
    }

    // A notification with buttons, through notify-send so it reaches ezshell's own notification server.
    // The x-ezshell-capture hint keeps the island from bannering it (it just showed the capture itself).
    // Each one gets its own notify-send, which waits for a button, so older ones keep working buttons.
    function notify(summary: string, file: string, actions: list<string>): void {
        const args = ["notify-send", "-a", "ezshell", "-i", "image-x-generic", "-h", "string:x-ezshell-capture:1"];
        if (file.endsWith(".png"))
            args.push("-h", `string:image-path:${file}`);
        for (const action of actions)
            args.push(`--action=${action}=${root.actionLabels[action]}`);
        args.push(summary, file.split("/").pop());
        notifier.createObject(root, {
            file: file,
            command: args
        });
    }

    function act(action: string, file: string): void {
        if (action === "open")
            Quickshell.execDetached(["xdg-open", file]);
        else if (action === "folder")
            Quickshell.execDetached(["xdg-open", file.slice(0, file.lastIndexOf("/"))]);
        else if (action === "edit" && root.editor !== "")
            Quickshell.execDetached(root.editor === "satty" ? ["satty", "--filename", file] : ["swappy", "-f", file]);
    }

    function status(): string {
        if (root.recording)
            return `recording to ${root.recordingFile}${Config.capture.audio ? " with sound" : ""}`;
        return root.busy ? "busy" : `idle; last screenshot: ${root.lastShot || "none"}`;
    }

    QtObject {
        id: internal

        property string pending: ""
        property string lastShot: ""
        property string editor: ""
        property string delayedMode: ""
        property string delayedPurpose: ""
        // "shot" or "record": what a picked region or window is for.
        property string purpose: "shot"
        property string recordingFile: ""
        property bool capturing: false
        property string lastRecorderLine: ""
        property var afterSettle: null
    }

    Timer {
        id: delay

        onTriggered: {
            if (internal.delayedPurpose === "record")
                root.record(internal.delayedMode);
            else
                root.screenshot(internal.delayedMode);
        }
    }

    Process {
        id: editorProbe

        running: true
        command: ["sh", "-c", "command -v satty || command -v swappy"]
        stdout: StdioCollector {
            onStreamFinished: internal.editor = text.trim().split("/").pop()
        }
    }

    Component {
        id: notifier

        Process {
            id: process

            required property string file

            running: true
            stdout: StdioCollector {
                id: choice

                onStreamFinished: root.act(choice.text.trim(), process.file)
            }
            onExited: process.destroy()
        }
    }

    // slurp prints "x,y wxh" for grim, or "wxh+x+y" (gpu-screen-recorder's -w region form) when asked; Esc (or any
    // cancel) exits non-zero with nothing to do.
    Process {
        id: selector

        stdout: StdioCollector {
            id: selection
        }
        onExited: code => {
            const area = selection.text.trim();
            if (code !== 0 || area === "")
                return;
            if (internal.purpose === "record")
                internal.afterSettle = () => root.startRecording(["-w", area]);
            else
                internal.afterSettle = () => root.shoot(["-g", area]);
            settleTimer.interval = root.settle;
            settleTimer.restart();
        }
    }

    Process {
        id: locator

        stdout: StdioCollector {
            id: activeWindow

            onStreamFinished: {
                const window = root.windowBox(activeWindow.text);
                if (!window)
                    console.warn("[capture] no active window to capture");
                else if (internal.purpose === "record")
                    root.startRecording(["-w", `${window.w}x${window.h}+${window.x}+${window.y}`]);
                else
                    root.shoot(["-g", `${window.x},${window.y} ${window.w}x${window.h}`]);
            }
        }
    }

    Timer {
        id: settleTimer

        onTriggered: internal.afterSettle?.()
    }

    Process {
        id: recorder

        // Its log ends with the encoder it picked once it's about to write frames, then reports fps.
        stderr: SplitParser {
            onRead: line => {
                internal.lastRecorderLine = line;
                if (!internal.capturing && /encoder|update fps/.test(line))
                    internal.capturing = true;
            }
        }
        onStarted: internal.capturing = false
        onExited: code => {
            // 0 after stop()'s SIGINT; anything else is a failed start or a crash.
            if (code === 0)
                root.notify("Recording saved", internal.recordingFile, ["open", "folder"]);
            else
                console.warn(`[capture] recording failed (${code}): ${internal.lastRecorderLine}`);
        }
    }

    Process {
        id: shooter

        stderr: StdioCollector {
            id: shotErrors
        }
        onExited: code => {
            if (code !== 0) {
                console.warn(`[capture] screenshot failed (${code}): ${shotErrors.text.trim()}`);
                return;
            }
            internal.lastShot = internal.pending;
            root.shotTaken(internal.lastShot);
            const actions = ["open", "folder"];
            if (root.editor !== "")
                actions.push("edit");
            root.notify("Screenshot saved and copied", internal.lastShot, actions);
        }
    }

    IpcHandler {
        // region, window, monitor or full.
        function screenshot(mode: string): void {
            root.screenshot(mode);
        }

        // The same after a pause in milliseconds, e.g. to open a menu first.
        function screenshotIn(mode: string, ms: int): void {
            root.screenshotIn(mode, ms);
        }

        // region, window or monitor; uses Config.capture.audio.
        function record(mode: string): void {
            root.record(mode);
        }

        function stop(): void {
            root.stop();
        }

        // Starts recording, or stops the one running (one key for both).
        function toggle(mode: string): void {
            root.toggle(mode);
        }

        function setAudio(enabled: bool): void {
            root.setAudio(enabled);
        }

        function status(): string {
            return root.status();
        }

        target: "capture"
    }
}
