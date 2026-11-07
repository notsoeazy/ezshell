pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// The main keyboard's layout. Read from `hyprctl -j devices` at start and after a config reload (the list
// of layouts can change), then kept current by Hyprland's activelayout event, which names the keymap.
Singleton {
    id: root

    readonly property string keyboard: internal.keyboard
    // Configured layouts, e.g. ["us", "de"], and the active one's index and full name ("English (US)").
    readonly property list<string> layouts: internal.layouts
    readonly property int index: internal.index
    readonly property string keymap: internal.keymap
    // "US": the active layout's code, for the island's label.
    readonly property string code: root.codeAt(root.index)
    readonly property bool multiple: root.layouts.length > 1

    // The main keyboard switched layout (not on start).
    signal switched(string keymap)

    function codeAt(index: int): string {
        return String(root.layouts[index] ?? "").toUpperCase();
    }

    function refresh(): void {
        devices.exec(["hyprctl", "-j", "devices"]);
    }

    function read(json: string): void {
        try {
            const keyboards = JSON.parse(json).keyboards ?? [];
            const main = keyboards.find(k => k.main) ?? keyboards[0];
            if (!main)
                return;
            internal.keyboard = main.name;
            internal.layouts = main.layout.split(",").map(l => l.trim()).filter(l => l !== "");
            internal.index = main.active_layout_index;
            internal.keymap = main.active_keymap;
        } catch (e) {
            console.warn(`[keyboard] unreadable hyprctl devices output: ${e.message}`);
        }
    }

    // activelayout data: "<keyboard>,<keymap>"; the keymap can itself contain commas.
    function onActiveLayout(data: string): void {
        const comma = data.indexOf(",");
        if (data.slice(0, comma) !== root.keyboard)
            return;
        const keymap = data.slice(comma + 1);
        if (keymap === root.keymap)
            return;
        internal.keymap = keymap;
        // The event names the keymap, not the index: ask for the index again.
        root.refresh();
        root.switched(keymap);
    }

    function status(): string {
        return `${root.keymap} (${root.layouts.join(", ")}) on ${root.keyboard}`;
    }

    Component.onCompleted: root.refresh()

    QtObject {
        id: internal

        property string keyboard: ""
        property list<string> layouts: []
        property int index: 0
        property string keymap: ""
    }

    Process {
        id: devices

        stdout: StdioCollector {
            id: output

            onStreamFinished: root.read(output.text)
        }
    }

    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "activelayout")
                root.onActiveLayout(event.data);
            else if (event.name === "configreloaded")
                root.refresh();
        }

        target: Hyprland
    }

    IpcHandler {
        function status(): string {
            return root.status();
        }

        target: "keyboard"
    }
}
