pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history, through cliphist. Something else must be feeding it
// (`wl-paste --watch cliphist store`); this only reads and copies.
Singleton {
    id: root

    // Newest first: { id, text, image }. `image` is true for a picture, whose
    // text is then a description of it.
    property list<var> entries: []

    // Read the history again; call when it is about to be shown.
    function refresh(): void {
        lister.running = true;
    }

    // Put a history entry back on the clipboard.
    function copy(id: string): void {
        // The id is passed as an argument, never pasted into the command.
        copier.command = ["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", id];
        copier.running = true;
    }

    function copyText(text: string): void {
        copier.command = ["wl-copy", "--", text];
        copier.running = true;
    }

    Process {
        id: lister

        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                // Each line is "id<TAB>preview".
                root.entries = text.split("\n").filter(line => line.includes("\t")).map(line => {
                    const tab = line.indexOf("\t");
                    const preview = line.slice(tab + 1);
                    const image = preview.startsWith("[[ binary data");
                    return {
                        id: line.slice(0, tab),
                        text: image ? preview.replace(/^\[\[ binary data (.*) \]\]$/, "Image, $1") : preview.trim(),
                        image: image
                    };
                });
            }
        }
    }

    Process {
        id: copier
    }
}
