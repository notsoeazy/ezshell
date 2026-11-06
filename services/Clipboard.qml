pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history from cliphist. Recording stays in Hyprland (`wl-paste --watch cliphist store` in
// execs.lua), so it survives shell restarts; this reads the history when a list opens and after each
// change made here, so no watcher runs. Commands go through `sh -c` with the id as an argument, never
// spliced into the script. Quickshell.clipboardText isn't used: it's empty unless a shell window has focus.
Singleton {
    id: root

    // Newest first: { id, preview, image } plus, for images, { size, format, width, height }.
    readonly property var entries: internal.entries
    readonly property bool loading: lister.running
    // Decoded image previews, id → file path; filled by thumbnail().
    readonly property var thumbs: internal.thumbs
    readonly property string thumbDir: `${Quickshell.env("XDG_RUNTIME_DIR")}/ezshell/clip`

    function refresh(): void {
        lister.exec(["cliphist", "list"]);
    }

    function copy(id: string): void {
        if (id === "")
            return;
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", id]);
    }

    // Puts text on the clipboard (the emoji picker); wl-copy takes it as an argument, no shell involved.
    function copyText(text: string): void {
        if (text !== "")
            Quickshell.execDetached(["wl-copy", "--", text]);
    }

    function remove(id: string): void {
        if (id === "")
            return;
        const script = 'printf "%s\\n" "$1" | cliphist delete && rm -f "$2"';
        root.run(["sh", "-c", script, "sh", id, root.thumbPath(id)]);
    }

    function wipe(): void {
        root.run(["sh", "-c", 'cliphist wipe && rm -rf "$1"', "sh", root.thumbDir]);
        internal.thumbs = {};
    }

    function thumbPath(id: string): string {
        return `${root.thumbDir}/${id}.png`;
    }

    // Decodes an image entry for its preview, once; rows ask for the ones they show.
    function thumbnail(id: string): void {
        if (root.thumbs[id] || internal.decoding.includes(id))
            return;
        internal.decoding = [...internal.decoding, id];
        root.decodeNext();
    }

    function decodeNext(): void {
        if (decoder.running || internal.decoding.length === 0)
            return;
        const id = internal.decoding[0];
        const script = 'mkdir -p -m 700 "$1" && cliphist decode "$2" > "$3"';
        decoder.exec(["sh", "-c", script, "sh", root.thumbDir, id, root.thumbPath(id)]);
    }

    // Runs a change to the history, one at a time so a quick second delete isn't cut off, then re-reads.
    function run(command: list<string>): void {
        internal.queue = [...internal.queue, command];
        root.runNext();
    }

    function runNext(): void {
        if (action.running || internal.queue.length === 0)
            return;
        action.exec(internal.queue[0]);
        internal.queue = internal.queue.slice(1);
    }

    // cliphist list: "<id>\t<preview>"; images preview as "[[ binary data 254 KiB png 1536x1448 ]]".
    function parse(text: string): var {
        const image = /^\[\[ binary data (\S+ \S+) (\w+) (\d+)x(\d+) \]\]$/;
        return text.split("\n").filter(line => line !== "").map(line => {
            const tab = line.indexOf("\t");
            const preview = line.slice(tab + 1);
            const match = preview.match(image);
            return {
                id: line.slice(0, tab),
                preview: preview,
                image: match !== null,
                size: match?.[1] ?? "",
                format: match?.[2] ?? "",
                width: Number(match?.[3] ?? 0),
                height: Number(match?.[4] ?? 0)
            };
        });
    }

    function status(): string {
        const images = root.entries.filter(e => e.image).length;
        return `${root.entries.length} entries, ${images} images`;
    }

    // Thumbnails from an earlier run may belong to ids that are gone; start the folder fresh.
    Component.onCompleted: root.run(["rm", "-rf", root.thumbDir])

    QtObject {
        id: internal

        property var entries: []
        property var thumbs: ({})
        property list<string> decoding: []
        property var queue: []
    }

    Process {
        id: lister

        stdout: StdioCollector {
            onStreamFinished: internal.entries = root.parse(text)
        }
    }

    Process {
        id: action

        onExited: code => {
            if (code !== 0)
                console.warn(`[clipboard] a history change exited with ${code}`);
            if (internal.queue.length > 0)
                root.runNext();
            else
                root.refresh();
        }
    }

    Process {
        id: decoder

        onExited: code => {
            const id = internal.decoding[0];
            internal.decoding = internal.decoding.slice(1);
            if (code === 0)
                internal.thumbs = Object.assign({}, internal.thumbs, {
                    [id]: root.thumbPath(id)
                });
            root.decodeNext();
        }
    }

    IpcHandler {
        function refresh(): void {
            root.refresh();
        }

        // Newest first, "<id>\t<preview>", as cliphist prints it.
        function list(): string {
            return root.entries.map(e => `${e.id}\t${e.preview}`).join("\n");
        }

        function copy(id: string): void {
            if (id === "")
                return;
            root.copy(id);
        }

        // `delete` is reserved in JavaScript.
        function remove(id: string): void {
            if (id === "")
                return;
            root.remove(id);
        }

        function wipe(): void {
            root.wipe();
        }

        function status(): string {
            return root.status();
        }

        target: "clipboard"
    }
}
