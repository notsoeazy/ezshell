pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The wallpaper and the images it can be picked from; modules/wallpaper draws it. Qt's FolderListModel
// reads one level only, so the folder and its subfolders are listed by one `find`, on start, when the
// folder changes and when a picker opens (no watching, no polling).
Singleton {
    id: root

    readonly property string current: Config.wallpaper.path
    readonly property string folder: Paths.expand(Config.wallpaper.folder)
    // Every image under the folder, sorted by path.
    readonly property list<string> files: internal.files
    readonly property bool scanning: scanner.running
    readonly property int index: root.files.indexOf(root.current)

    function set(path: string): void {
        Config.wallpaper.path = Paths.expand(path);
    }

    function rescan(): void {
        const images = ["(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png"];
        images.push("-o", "-iname", "*.webp", ")");
        // -L follows symlinked folders; hidden files and folders (.git) are pruned below the top level.
        const hidden = ["-mindepth", "1", "-name", ".*", "-prune", "-o"];
        scanner.exec(["find", "-L", root.folder, ...hidden, "-type", "f", ...images, "-print"]);
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
    }

    Process {
        id: scanner

        stdout: StdioCollector {
            onStreamFinished: internal.files = text.split("\n").filter(line => line !== "").sort()
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    console.warn(`[wallpapers] find: ${text.trim().split("\n")[0]}`);
            }
        }
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
