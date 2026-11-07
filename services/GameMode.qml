pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config
import qs.services

// Game mode: animations, blur, shadows and gaps off, and do not disturb on. Turning it on first reads the
// current values (never hardcoded) and keeps them in ~/.local/state/ezshell/gamemode.json, so turning it
// off restores exactly them, even after a shell restart. A Hyprland config reload while it's on resets
// those options, so game mode applies itself again.
Singleton {
    id: root

    // Hyprland option → its path in a Lua hl.config table; gaps are "css" values ("5 5 5 5").
    readonly property var options: ({
            "animations:enabled": "animations.enabled",
            "decoration:blur:enabled": "decoration.blur.enabled",
            "decoration:shadow:enabled": "decoration.shadow.enabled",
            "general:gaps_in": "general.gaps_in",
            "general:gaps_out": "general.gaps_out"
        })
    readonly property var gameValues: ({
            "animations:enabled": false,
            "decoration:blur:enabled": false,
            "decoration:shadow:enabled": false,
            "general:gaps_in": 0,
            "general:gaps_out": 0
        })
    readonly property bool active: root.stateActive
    readonly property bool busy: reader.running
    // gamemode.json, through aliases so the functions reach it by name.
    property alias stateActive: store.active
    property alias savedValues: store.saved
    property alias savedDnd: store.dnd

    signal changed(bool active)

    function on(): void {
        if (root.active || root.busy)
            return;
        // Read first; turning on continues in the reader once the values are in.
        const script = 'for o; do hyprctl -j getoption "$o" | tr -d "\\n"; echo; done';
        reader.exec(["sh", "-c", script, "sh", ...Object.keys(root.options)]);
    }

    function off(): void {
        if (!root.active)
            return;
        root.apply(root.savedValues);
        Notifs.setDnd(root.savedDnd);
        root.stateActive = false;
        root.savedValues = {};
        root.changed(false);
    }

    function toggle(): void {
        if (root.active)
            root.off();
        else
            root.on();
    }

    // getoption JSON → a plain value: bool, int, or the gaps' "css" string.
    function valueOf(option: var): var {
        if (option.bool !== undefined)
            return option.bool;
        if (option.int !== undefined)
            return option.int;
        if (option.css !== undefined) {
            const parts = option.css.trim().split(/\s+/);
            return parts.every(p => p === parts[0]) ? Number(parts[0]) : option.css;
        }
        return option.float ?? option.str ?? null;
    }

    function readValues(text: string): var {
        const values = {};
        for (const line of text.split("\n").filter(l => l.trim() !== "")) {
            const option = JSON.parse(line);
            values[option.option] = root.valueOf(option);
        }
        return values;
    }

    // { "decoration:blur:enabled": false } → "{ decoration = { blur = { enabled = false } } }"
    function luaTable(values: var): string {
        const tree = {};
        for (const [option, value] of Object.entries(values)) {
            const path = root.options[option].split(".");
            let node = tree;
            for (const key of path.slice(0, -1))
                node = node[key] = node[key] ?? {};
            node[path[path.length - 1]] = value;
        }
        return root.luaValue(tree);
    }

    function luaValue(node: var): string {
        if (typeof node === "object")
            return `{ ${Object.entries(node).map(([key, value]) => `${key} = ${root.luaValue(value)}`).join(", ")} }`;
        return typeof node === "string" ? JSON.stringify(node) : `${node}`;
    }

    // hyprctl eval for a Lua config, or keywords for a classic one: eval answers "ok" only under Lua, so the
    // keywords run only when it doesn't (Hyprland.usingLua can still be unset right after a shell start).
    function apply(values: var): void {
        const lua = `hl.config(${root.luaTable(values)})`;
        const keywords = Object.entries(values).map(([o, v]) => `keyword ${o} ${v === true ? 1 : v === false ? 0 : v}`);
        const script = '[ "$(hyprctl eval "$1")" = ok ] || hyprctl --batch "$2"';
        applier.exec(["sh", "-c", script, "sh", lua, keywords.join(";")]);
    }

    function status(): string {
        if (!root.active)
            return "off";
        return `on; restores ${Object.entries(root.savedValues).map(([o, v]) => `${o}=${v}`).join(", ")}`;
    }

    Process {
        id: reader

        stdout: StdioCollector {
            id: current

            onStreamFinished: {
                let saved;
                try {
                    saved = root.readValues(current.text);
                } catch (e) {
                    console.warn(`[gamemode] couldn't read the current options: ${e.message}`);
                    return;
                }
                if (Object.keys(saved).length !== Object.keys(root.options).length) {
                    console.warn("[gamemode] couldn't read every option; not turning on");
                    return;
                }
                root.savedValues = saved;
                root.savedDnd = Notifs.dnd;
                root.stateActive = true;
                root.apply(root.gameValues);
                Notifs.setDnd(true);
                root.changed(true);
            }
        }
    }

    Process {
        id: applier

        stdout: StdioCollector {
            id: answer

            onStreamFinished: {
                const text = answer.text.trim();
                if (text !== "" && text !== "ok" && !/^(ok\s*)+$/.test(text))
                    console.warn(`[gamemode] hyprctl: ${text}`);
            }
        }
    }

    // Only this service writes it. A missing file is the normal "never used" state.
    FileView {
        path: `${Paths.state}/gamemode.json`
        printErrors: false
        onAdapterUpdated: writeAdapter()
        onLoaded: {
            if (root.stateActive)
                root.apply(root.gameValues);
        }

        JsonAdapter {
            id: store

            property bool active: false
            // The values game mode replaced, and do not disturb as it was.
            property var saved: ({})
            property bool dnd: false
        }
    }

    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "configreloaded" && root.active)
                root.apply(root.gameValues);
        }

        target: Hyprland
    }

    IpcHandler {
        function on(): void {
            root.on();
        }

        function off(): void {
            root.off();
        }

        function toggle(): void {
            root.toggle();
        }

        function status(): string {
            return root.status();
        }

        target: "gamemode"
    }
}
