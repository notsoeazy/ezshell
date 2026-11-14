pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Screen backlight, through brightnessctl. The current value is read from the
// kernel's file for the device, so changes made elsewhere are picked up too.
Singleton {
    id: root

    // Name of the backlight device, found once at startup.
    property string device
    property int max: 1
    property int raw
    readonly property bool available: device.length > 0
    // 0..1
    readonly property real value: Math.max(0, Math.min(1, raw / max))
    // Never go fully dark.
    readonly property real minimum: 0.01

    function set(value: real): void {
        if (!available)
            return;

        const target = Math.max(minimum, Math.min(1, value));
        // Show the new value at once; the file confirms it a moment later.
        raw = Math.round(target * max);
        setter.command = ["brightnessctl", "--quiet", "--device", device, "set", `${raw}`];
        setter.running = true;
    }

    function change(delta: real): void {
        set(value + delta);
    }

    // "device,class,current,percent,max"
    Process {
        running: true
        command: ["brightnessctl", "--machine-readable", "--class", "backlight"]

        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split("\n")[0].split(",");
                if (fields.length < 5) {
                    console.warn("Brightness: no backlight device found; brightness control is off");
                    return;
                }
                root.max = Math.max(1, parseInt(fields[4]));
                root.raw = parseInt(fields[2]);
                root.device = fields[0];
            }
        }
    }

    Process {
        id: setter
    }

    FileView {
        path: root.available ? `/sys/class/backlight/${root.device}/brightness` : ""
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const current = parseInt(text());
            if (!isNaN(current) && !setter.running)
                root.raw = current;
        }
    }
}
