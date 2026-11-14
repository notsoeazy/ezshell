pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

// Screenshots and screen recordings. Choosing an area happens in
// modules/capture, which reads `picking` and answers with `picked`.
//
// A screenshot starts by saving a still of every screen, so the choice is
// made on a frozen picture: menus and hover states can be captured, and the
// chooser itself is never in the shot.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    // Stills and unsaved screenshots live here, and go when the session ends.
    readonly property string scratch: `${Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"}/ezshell`
    readonly property list<string> actions: ["edit", "copy", "save"]
    readonly property list<string> recordModes: ["screen", "sound", "region"]

    // What an area is being chosen for: "screenshot", "record", or "".
    property string picking
    // What to do with the screenshot being taken.
    property string action
    // Changes with every set of stills, so pictures are read afresh.
    property int stamp

    readonly property bool recording: recorder.running
    // Seconds recorded so far.
    property int elapsed
    property string recordingPath

    function expand(path: string): string {
        return path.replace(/^~/, home);
    }

    function still(screen: string): string {
        return `${scratch}/still-${screen}.ppm`;
    }

    function timestamp(): string {
        return Qt.formatDateTime(new Date(), "yyyyMMdd-HHmmss");
    }

    // "0:07", "12:34", "1:02:03"
    function clock(seconds: int): string {
        const s = `${seconds % 60}`.padStart(2, "0");
        const m = Math.floor(seconds / 60) % 60;
        const h = Math.floor(seconds / 3600);
        return h > 0 ? `${h}:${`${m}`.padStart(2, "0")}:${s}` : `${m}:${s}`;
    }

    // Choose an area or a window, then do `action` with it: "edit", "copy"
    // or "save"; anything else means the one set in the config.
    function screenshot(action: string): void {
        if (picking.length > 0 || freezer.running)
            return;

        root.action = actions.includes(action) ? action : Config.capture.screenshotAction;
        Hypr.refreshWindows();
        freezer.screens = Quickshell.screens.map(screen => screen.name);
        freezer.whole = "";
        freezer.running = true;
    }

    // The whole of the focused screen, with no choosing.
    function screenshotScreen(action: string): void {
        if (picking.length > 0 || freezer.running)
            return;

        root.action = actions.includes(action) ? action : Config.capture.screenshotAction;
        freezer.screens = [Hypr.focusedMonitor];
        freezer.whole = Hypr.focusedMonitor;
        freezer.running = true;
    }

    // The same, once the island has had time to close: for buttons on it.
    function screenshotSoon(action: string): void {
        soon.kind = "screenshot";
        soon.argument = action;
        soon.restart();
    }

    function recordSoon(mode: string): void {
        soon.kind = "record";
        soon.argument = mode;
        soon.restart();
    }

    // Start recording, or stop if one is running. "screen", "sound" (the
    // screen with sound) or "region"; anything else means the config's mode.
    function record(mode: string): void {
        if (recording) {
            stop();
            return;
        }
        const chosen = recordModes.includes(mode) ? mode : Config.capture.recordMode;
        if (chosen === "region") {
            Hypr.refreshWindows();
            picking = "record";
        } else {
            startRecording(["-w", Hypr.focusedMonitor.length > 0 ? Hypr.focusedMonitor : "screen"], chosen === "sound");
        }
    }

    function stop(): void {
        // Interrupt: the recorder finishes the file and exits.
        if (recorder.running)
            recorder.signal(2);
    }

    function cancel(): void {
        picking = "";
    }

    // The chooser's answer: a rectangle in the screen's own coordinates;
    // `scale` is the screen's pixels per unit.
    function picked(screen: ShellScreen, area: rect, scale: real): void {
        const kind = picking;
        picking = "";
        const width = Math.round(area.width * scale);
        const height = Math.round(area.height * scale);
        if (width < 1 || height < 1)
            return;

        if (kind === "screenshot") {
            deliver(still(screen.name), `${width}x${height}+${Math.round(area.x * scale)}+${Math.round(area.y * scale)}`);
        } else if (kind === "record") {
            // The recorder takes a place on the whole desktop, not on one screen.
            startRecording(["-w", "region", "-region", `${width}x${height}+${Math.round((screen.x + area.x) * scale)}+${Math.round((screen.y + area.y) * scale)}`], false);
        }
    }

    // Cut the still (all of it if `crop` is empty) into a PNG, then edit,
    // copy or save it.
    function deliver(source: string, crop: string): void {
        const saving = action === "save";
        const target = saving ? `${expand(Config.capture.screenshotDirectory)}/screenshot-${timestamp()}.png` : `${scratch}/screenshot-${timestamp()}.png`;
        const cut = crop.length > 0 ? ["-crop", crop, "+repage"] : [];
        finisher.message = action === "edit" ? "" : saving ? "Screenshot saved and copied" : "Screenshot copied";
        finisher.command = ["sh", "-c", 'out="$1"; shift; mkdir -p "$(dirname "$out")" && magick "$@" "$out" && { [ "$ACTION" = edit ] || wl-copy --type image/png < "$out"; } && printf %s "$out"', "sh", target, source, ...cut];
        finisher.environment = ({
                "ACTION": action
            });
        finisher.running = true;
    }

    readonly property string recorderScript: 'out="$1"; log="$2"; shift 2; mkdir -p "$(dirname "$out")" "$(dirname "$log")"; gpu-screen-recorder -o "$out" "$@" > "$log" 2>&1 & pid=$!; trap "kill -INT $pid" INT TERM HUP; wait $pid; code=$?; if [ $code -gt 128 ]; then wait $pid; code=$?; fi; exit $code'

    function startRecording(target: list<string>, sound: bool): void {
        const audio = !sound ? [] : ["-a", Config.capture.recordMicrophone ? "default_output|default_input" : "default_output"];
        recordingPath = `${expand(Config.capture.recordingDirectory)}/recording-${timestamp()}.mp4`;
        elapsed = 0;
        // A small script stands between the shell and the recorder: it
        // passes on the request to stop, and (through setpriv) is told if
        // the shell goes, so the file is finished and not left growing. The
        // recorder's messages go to a file, since a closed pipe would kill it.
        recorder.command = ["setpriv", "--pdeathsig", "TERM", "sh", "-c", recorderScript, "sh", recordingPath, `${scratch}/recorder.log`, ...target, "-f", `${Config.capture.recordFps}`, ...audio];
        recorder.running = true;
    }

    // One still per screen, then open the chooser (or, for a whole screen,
    // go straight on).
    Process {
        id: freezer

        property list<string> screens
        // The screen to take whole, if no choosing is wanted.
        property string whole

        command: ["sh", "-c", 'dir="$1"; shift; mkdir -p "$dir" && for s; do grim -t ppm -o "$s" "$dir/still-$s.ppm" || exit 1; done', "sh", root.scratch, ...screens]
        onExited: code => {
            if (code !== 0) {
                Osd.toast("error", "The screen could not be captured");
                return;
            }
            root.stamp++;
            if (whole.length > 0)
                root.deliver(root.still(whole), "");
            else
                root.picking = "screenshot";
        }
    }

    Process {
        id: finisher

        property string message

        onExited: code => {
            if (code !== 0)
                Osd.toast("error", "The screenshot could not be saved");
            else if (message.length > 0)
                Osd.announce("capture", "screenshot_region", message, false);
        }

        // The file's path: the editor opens it.
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.action === "edit" && text.length > 0)
                    Quickshell.execDetached([...Config.capture.editor, text]);
            }
        }
    }

    Process {
        id: recorder

        onExited: code => {
            if (code !== 0)
                console.warn(`Capture: the recorder exited with code ${code}; its messages are in ${root.scratch}/recorder.log`);
            if (code === 0) {
                Quickshell.execDetached(["wl-copy", root.recordingPath]);
                Osd.announce("capture", "videocam", "Recording saved, path copied", false);
            } else {
                Osd.toast("error", "The recording could not be made");
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.elapsed++
    }

    Timer {
        id: soon

        property string kind
        property string argument

        interval: Tokens.motion.spatialSlow.duration
        onTriggered: {
            if (kind === "screenshot")
                root.screenshot(argument);
            else
                root.record(argument);
        }
    }
}
