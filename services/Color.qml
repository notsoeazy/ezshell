pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Color picker: hyprpicker freezes the screen and prints the clicked color as hex; Esc prints nothing.
// Without -a it doesn't copy by itself, so the copy goes through Clipboard like every other copy.
Singleton {
    id: root

    readonly property bool picking: picker.running
    readonly property string last: internal.last

    // A picked color, "#rrggbb".
    signal picked(string hex)

    function pick(): void {
        if (!root.picking)
            picker.exec(["hyprpicker", "-f", "hex"]);
    }

    // After a pause, so a menu can close first: hyprpicker freezes the screen as it is.
    function pickIn(ms: int): void {
        delay.interval = Math.max(0, ms);
        delay.restart();
    }

    QtObject {
        id: internal

        property string last: ""
    }

    Timer {
        id: delay

        onTriggered: root.pick()
    }

    Process {
        id: picker

        stdout: StdioCollector {
            id: output

            onStreamFinished: {
                const hex = output.text.trim().toLowerCase();
                if (!/^#[0-9a-f]{6}$/.test(hex))
                    return;
                internal.last = hex;
                Clipboard.copyText(hex);
                root.picked(hex);
            }
        }
    }

    IpcHandler {
        function pick(): void {
            root.pick();
        }

        function pickIn(ms: int): void {
            root.pickIn(ms);
        }

        function last(): string {
            return root.last;
        }

        target: "color"
    }
}
