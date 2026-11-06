pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    readonly property string device: internal.device
    readonly property bool available: internal.device !== "" && internal.max > 0
    // False until the sysfs file has been read once; level is 0 until then.
    readonly property bool ready: root.available && current.loaded
    readonly property real level: root.ready ? parseInt(current.text()) / internal.max : 0

    function set(level: real): void {
        if (!root.available)
            return;
        // Floor of 1%: a backlight at 0 looks like a dead screen.
        const percent = Math.round(Math.max(0.01, Math.min(1, level)) * 100);
        setter.exec(["brightnessctl", "-q", "-d", root.device, "set", `${percent}%`]);
    }

    function up(): void {
        root.set(root.level + Config.brightness.step);
    }

    function down(): void {
        root.set(root.level - Config.brightness.step);
    }

    function status(): string {
        return root.available ? `${Math.round(root.level * 100)}% (${root.device})` : "no backlight";
    }

    QtObject {
        id: internal

        property string device: ""
        property int max: 0
    }

    // One-shot: finds the default backlight. Output is "device,class,current,percent,max".
    Process {
        running: true
        command: ["brightnessctl", "-m", "-c", "backlight", "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(",");
                internal.max = parseInt(fields[4]) || 0;
                internal.device = fields[0] ?? "";
            }
        }
    }

    Process {
        id: setter

        onExited: code => {
            if (code !== 0)
                console.warn(`[brightness] brightnessctl exited with ${code}`);
        }
    }

    // sysfs sends inotify events for every write, so changes from any tool show up here.
    FileView {
        id: current

        path: internal.device ? `/sys/class/backlight/${internal.device}/brightness` : ""
        watchChanges: true
        onFileChanged: reload()
    }

    IpcHandler {
        function up(): void {
            root.up();
        }

        function down(): void {
            root.down();
        }

        function set(level: real): void {
            root.set(level);
        }

        function status(): string {
            return root.status();
        }

        target: "brightness"
    }
}
