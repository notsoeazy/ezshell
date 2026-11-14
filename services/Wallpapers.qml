pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The wallpapers on disk, which one is set, and a preview that can stand in
// for it while choosing.
Singleton {
    id: root

    readonly property string directory: Config.wallpaper.directory.replace(/^~/, Quickshell.env("HOME"))
    // Full paths, sorted by file name.
    property list<string> list: []
    // The wallpaper that is set; the first one found until one is chosen.
    readonly property string current: ShellState.wallpaper.length > 0 ? ShellState.wallpaper : (list[0] ?? "")
    // Shown in place of `current` while set, without being remembered.
    property string preview
    readonly property string showing: preview.length > 0 ? preview : current

    // Small copies of the pictures, for the selector. Reading a full-size
    // wallpaper just to draw it a few centimetres wide is slow, so each one is
    // shrunk once and kept on disk; after that the selector opens at once.
    readonly property string thumbnailDir: `${Quickshell.env("XDG_CACHE_HOME") || `${Quickshell.env("HOME")}/.cache`}/ezshell/thumbnails`
    // Twice the size they are drawn at, so they stay sharp.
    readonly property string thumbnailSize: `${Tokens.island.wallpaperThumb * 2}x${Tokens.island.wallpaperThumb * 2 * 9 / 16}`
    // Picture path -> its thumbnail, for those that exist so far.
    property var thumbnails: ({})
    // Ones reported since the last update, added in batches.
    property var arriving: ({})

    // The thumbnail if there is one yet, else the picture itself.
    function thumbnail(path: string): string {
        return thumbnails[path] ?? path;
    }

    function refresh(): void {
        finder.running = true;
    }

    function set(path: string): void {
        ShellState.wallpaper = path;
        preview = "";
    }

    function next(): void {
        if (list.length > 0)
            set(list[(list.indexOf(current) + 1) % list.length]);
    }

    function name(path: string): string {
        return path.slice(path.lastIndexOf("/") + 1);
    }

    onDirectoryChanged: refresh()

    Process {
        id: finder

        running: true
        command: ["find", "-L", root.directory, "-maxdepth", "3", "-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")", "-not", "-path", "*/.*"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.list = text.split("\n").filter(path => path.length > 0).sort((a, b) => root.name(a).localeCompare(root.name(b)));
                thumbnailer.running = true;
            }
        }
    }

    // Makes any thumbnail that is missing or older than its picture, and
    // reports each one as "picture<TAB>thumbnail". Runs at low priority; the
    // first run over a large folder takes a minute or so, later ones a moment.
    Process {
        id: thumbnailer

        command: ["nice", "-n", "19", "sh", "-c", `
            dir=$1; size=$2; shift 2
            command -v magick >/dev/null || { echo "missing-magick"; exit 0; }
            mkdir -p "$dir"
            for src; do
                key=$(printf %s "$src" | md5sum | cut -d" " -f1)
                dst="$dir/$key.jpg"
                if [ ! -e "$dst" ] || [ "$src" -nt "$dst" ]; then
                    magick "$src[0]" -thumbnail "$size^" -gravity center -extent "$size" -quality 85 "$dst.part.jpg" 2>/dev/null && mv "$dst.part.jpg" "$dst" || continue
                fi
                printf "%s\t%s\n" "$src" "$dst"
            done`, "sh", root.thumbnailDir, root.thumbnailSize, ...root.list]

        stdout: SplitParser {
            onRead: line => {
                if (line === "missing-magick") {
                    console.warn("Wallpapers: ImageMagick (magick) is not installed; the selector will read full-size pictures");
                    return;
                }
                const tab = line.indexOf("\t");
                if (tab > 0) {
                    root.arriving[line.slice(0, tab)] = `file://${line.slice(tab + 1)}`;
                    flush.restart();
                }
            }
        }
    }

    // Thumbnails arrive one line at a time; take them in a few at a time so
    // the selector is not redrawn hundreds of times.
    Timer {
        id: flush

        interval: 100
        onTriggered: {
            root.thumbnails = Object.assign({}, root.thumbnails, root.arriving);
            root.arriving = {};
        }
    }
}
