pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The wallpaper and the images it can be picked from; modules/wallpaper draws it. Qt's FolderListModel
// reads one level only, so the folder and its subfolders are listed by one `find`, on start, when the
// folder changes and when a picker opens (no watching, no polling). `scripts/wallpaper-thumbs.sh`
// builds 448x252 JPEG thumbnails in ~/.cache/ezshell/wallpapers so the pickers never decode 20 MB PNGs.
Singleton {
    id: root

    readonly property string current: Config.wallpaper.path
    readonly property string folder: Paths.expand(Config.wallpaper.folder)
    readonly property string thumbDir: `${Paths.cache}/wallpapers`
    // Every image under the folder, sorted by path.
    readonly property list<string> files: internal.files
    // Source path → cached thumbnail JPEG path.
    readonly property var thumbs: internal.thumbs
    readonly property bool scanning: scanner.running
    readonly property int index: root.files.indexOf(root.current)

    function set(path: string): void {
        Config.wallpaper.path = Paths.expand(path);
    }

    function thumbFor(path: string): string {
        return root.thumbs[path] ?? path;
    }

    function rescan(): void {
        const images = ["(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png"];
        images.push("-o", "-iname", "*.webp", ")");
        // -L follows symlinked folders; hidden files and folders (.git) are pruned below the top level.
        const hidden = ["-mindepth", "1", "-name", ".*", "-prune", "-o"];
        scanner.exec(["find", "-L", root.folder, ...hidden, "-type", "f", ...images, "-print"]);
    }

    // Prioritises the requested paths (e.g. the current page) at the front of the thumbnail queue.
    function ensureThumbs(paths: list<string>): void {
        const missing = paths.filter(p => p !== "" && !root.thumbs[p]);
        if (missing.length === 0)
            return;
        const rest = internal.queue.filter(p => !missing.includes(p));
        internal.queue = [...missing, ...rest];
        root.thumbNext();
    }

    function thumbNext(): void {
        if (thumber.running || internal.queue.length === 0)
            return;
        const batch = internal.queue.slice(0, 24);
        internal.queue = internal.queue.slice(24);
        thumber.exec(["sh", Quickshell.shellPath("scripts/wallpaper-thumbs.sh"), root.thumbDir, ...batch]);
    }

    // Any image but the current one.
    function random(): void {
        const count = root.files.length;
        if (count === 0) {
            root.warnEmpty();
            return;
        }
        let pick = Math.floor(Math.random() * Math.max(count - 1, 1));
        if (root.index >= 0 && pick >= root.index && count > 1)
            pick++;
        root.set(root.files[pick]);
    }

    // Folder order, wrapping around; from outside the folder, starts at the first (or last) image.
    function step(by: int): void {
        const count = root.files.length;
        if (count === 0) {
            root.warnEmpty();
            return;
        }
        const start = root.index >= 0 ? root.index + by : (by > 0 ? 0 : -1);
        root.set(root.files[(start % count + count) % count]);
    }

    function warnEmpty(): void {
        console.warn(`[wallpapers] no images in ${root.folder}`);
    }

    function list(): string {
        return root.files.map(f => `${f === root.current ? "*" : " "} ${f}`).join("\n");
    }

    Component.onCompleted: root.rescan()
    // Any change, by hand or by the slideshow, starts a full interval again.
    onCurrentChanged: {
        // restart() would also start a stopped timer.
        if (slideshow.running)
            slideshow.restart();
    }

    QtObject {
        id: internal

        property list<string> files: []
        property var thumbs: ({})
        property list<string> queue: []
    }

    Process {
        id: scanner

        stdout: StdioCollector {
            onStreamFinished: {
                const found = text.split("\n").filter(line => line !== "").sort();
                internal.files = found;
                root.ensureThumbs(found);
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const first = text.trim().split("\n")[0];
                // A missing folder isn't an error: the pickers say there are no images.
                if (first !== "" && !(first.includes(root.folder) && first.endsWith("No such file or directory")))
                    console.warn(`[wallpapers] find: ${first}`);
            }
        }
    }

    Process {
        id: thumber

        stdout: SplitParser {
            onRead: line => {
                const tab = line.indexOf("\t");
                if (tab <= 0)
                    return;
                const src = line.slice(0, tab);
                const out = line.slice(tab + 1).trim();
                if (out !== "")
                    internal.thumbs = Object.assign({}, internal.thumbs, {
                        [src]: out
                    });
            }
        }
        onExited: root.thumbNext()
    }

    // Runs only while a slideshow is set and there's something to change to.
    Timer {
        id: slideshow

        interval: Config.wallpaper.interval * 60000
        running: Config.wallpaper.interval > 0 && root.files.length > 1
        repeat: true
        onTriggered: root.step(1)
    }

    Connections {
        function onFolderChanged(): void {
            root.rescan();
        }

        target: Config.wallpaper
    }

    IpcHandler {
        function set(path: string): void {
            root.set(path);
        }

        function get(): string {
            return root.current;
        }

        function random(): void {
            root.random();
        }

        function next(): void {
            root.step(1);
        }

        function previous(): void {
            root.step(-1);
        }

        function list(): string {
            return root.list();
        }

        function rescan(): void {
            root.rescan();
        }

        target: "wallpaper"
    }
}
