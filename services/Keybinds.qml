pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.utils

// Hyprland's binds for the cheat sheet, from `hyprctl -j binds` at start and after every config reload.
// Lua binds only report their keys; what a bind does comes from its description
// (`hl.bind(keys, fn, { description = "Media: Play or pause" })`), split into group and text.
Singleton {
    id: root

    // [{ keys, group, text, submap }], described ones first, each sorted by group then keys.
    readonly property var binds: internal.binds
    readonly property int described: root.binds.filter(b => b.text !== "").length

    function refresh(): void {
        hyprctl.exec(["hyprctl", "-j", "binds"]);
    }

    function entry(bind: var): var {
        const [group, text] = KeyCombo.split(bind.description ?? "");
        return {
            keys: KeyCombo.combo(bind.modmask, bind.key, bind.keycode),
            group: group,
            text: text,
            submap: bind.submap ?? ""
        };
    }

    // Described first, then by group and keys; Hyprland lists binds in config order.
    function order(a: var, b: var): int {
        if ((a.text === "") !== (b.text === ""))
            return a.text === "" ? 1 : -1;
        return a.group.localeCompare(b.group) || a.keys.localeCompare(b.keys);
    }

    function read(json: string): void {
        try {
            // One entry per keys + description: press and release binds of one key show once.
            const seen = new Set();
            internal.binds = JSON.parse(json).map(root.entry).filter(b => {
                const id = `${b.submap}|${b.keys}|${b.group}|${b.text}`;
                return !seen.has(id) && seen.add(id);
            }).sort(root.order);
        } catch (e) {
            console.warn(`[keybinds] unreadable hyprctl binds output: ${e.message}`);
        }
    }

    function list(): string {
        return root.binds.map(b => `${b.keys}\t${b.group ? b.group + ": " : ""}${b.text}`).join("\n");
    }

    function status(): string {
        return `${root.binds.length} binds, ${root.described} with a description`;
    }

    Component.onCompleted: root.refresh()

    QtObject {
        id: internal

        property var binds: []
    }

    Process {
        id: hyprctl

        stdout: StdioCollector {
            id: output

            onStreamFinished: root.read(output.text)
        }
    }

    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "configreloaded")
                root.refresh();
        }

        target: Hyprland
    }

    IpcHandler {
        function list(): string {
            return root.list();
        }

        function status(): string {
            return root.status();
        }

        function refresh(): void {
            root.refresh();
        }

        target: "keybinds"
    }
}
