pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.utils

// Turns the wallpaper into theme.json, which themes/Colors.qml reads (this service never touches Colors).
// One matugen Process serves both previews and the real theme. Always the dark variant: the island is
// black, and the shell has no light mode. Without matugen, one warning and the palette stays as it is.
Singleton {
    id: root

    readonly property string file: `${Paths.state}/theme.json`
    // "wallpaper" or "palette" for what was last written; "" before the first write this session.
    readonly property string source: internal.source
    // Role map from the last preview run (settings app), or null.
    readonly property var preview: internal.preview
    readonly property string error: internal.error
    // Contrast fixes applied to the last generated palette, e.g. "primaryFg on primary 3.9 → 4.6".
    readonly property list<string> fixes: internal.fixes
    readonly property list<string> schemes: Matugen.schemes

    // Writes what the config asks for: the wallpaper's palette, or the built-in one.
    function regenerate(): void {
        if (Config.theme.fromWallpaper && Config.wallpaper.path !== "")
            root.run(Config.wallpaper.path, Config.theme.scheme, "apply");
        else
            root.write(Palettes.base, "palette");
    }

    function previewWallpaper(path: string, scheme: string): void {
        root.run(Paths.expand(path), scheme, "preview");
    }

    function setWallpaper(path: string): void {
        Config.wallpaper.path = Paths.expand(path);
    }

    function setScheme(scheme: string): void {
        if (root.schemes.includes(scheme))
            Config.theme.scheme = scheme;
        else
            console.warn(`[theme] unknown scheme ${scheme}`);
    }

    function setFromWallpaper(enabled: bool): void {
        Config.theme.fromWallpaper = enabled;
    }

    function run(path: string, scheme: string, purpose: string): void {
        internal.purpose = purpose;
        internal.error = "";
        // --prefer: matugen otherwise asks which source color to use; --fallback-color: images without a
        // usable color get the Nord blue.
        const choice = ["--prefer", "saturation", "--fallback-color", Palettes.base.primary];
        matugen.exec(["matugen", "image", path, "--json", "hex", "--dry-run", "-m", "dark", "-t", scheme, ...choice]);
    }

    // Black surface like the island, then the text/background pairs that must stay readable.
    function fit(palette: var): var {
        palette.surface = Palettes.base.surface;
        const fixes = [];
        for (const [fg, bg, minimum] of Matugen.pairs) {
            // A null background is the island: always black, like the built-in surface.
            const background = Qt.color(bg ? palette[bg] : Palettes.base.surface);
            const before = Contrast.ratio(Qt.color(palette[fg]), background);
            if (before >= minimum)
                continue;
            const fixed = Contrast.ensure(Qt.color(palette[fg]), background, minimum);
            palette[fg] = fixed.toString();
            const after = Contrast.ratio(fixed, background);
            fixes.push(`${fg} on ${bg ?? "island"} ${before.toFixed(1)} → ${after.toFixed(1)}`);
        }
        internal.fixes = fixes;
        return palette;
    }

    function write(palette: var, source: string): void {
        writer.setText(JSON.stringify(palette, null, 4));
        internal.source = source;
    }

    function status(): string {
        const wallpaper = `wallpaper (${Config.theme.scheme}): ${Config.wallpaper.path || "none set"}`;
        const using = Config.theme.fromWallpaper ? wallpaper : "built-in palette";
        const fixes = root.fixes.length > 0 ? `; contrast fixes: ${root.fixes.join("; ")}` : "";
        return `${using}${root.error !== "" ? `; error: ${root.error}` : ""}${fixes}`;
    }

    QtObject {
        id: internal

        property string purpose: ""
        property string source: ""
        property var preview: null
        property string error: ""
        property list<string> fixes: []
        property bool warnedMissing: false
    }

    Process {
        id: matugen

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "")
                    return;
                try {
                    const palette = root.fit(Matugen.toPalette(JSON.parse(text), Palettes.base));
                    if (internal.purpose === "preview")
                        internal.preview = palette;
                    else
                        root.write(palette, "wallpaper");
                } catch (e) {
                    internal.error = `unreadable matugen output: ${e.message}`;
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    internal.error = text.trim().split("\n").slice(-1)[0];
            }
        }
        onExited: code => {
            // 127: no such command (Process runs it directly, so it's the exec failure code).
            if (code === 127 || code === -1) {
                internal.error = "matugen is not installed";
                if (!internal.warnedMissing)
                    console.warn("[theme] matugen not found; keeping the current palette");
                internal.warnedMissing = true;
            } else if (code !== 0 && code !== 15) {
                // 15 is SIGTERM: a newer run replaced this one (exec restarts the Process), not an error.
                console.warn(`[theme] matugen exited with ${code}: ${internal.error}`);
            }
        }
    }

    FileView {
        id: writer

        path: root.file
        // Writes go to a temp file and rename, so Colors never reads half a file.
        atomicWrites: true
    }

    // Wallpaper, scheme or the switch changed (settings app, IPC, a hand edit): rebuild the theme.
    Connections {
        function onPathChanged(): void {
            Qt.callLater(root.regenerate);
        }

        target: Config.wallpaper
    }

    Connections {
        function onFromWallpaperChanged(): void {
            Qt.callLater(root.regenerate);
        }

        function onSchemeChanged(): void {
            Qt.callLater(root.regenerate);
        }

        target: Config.theme
    }

    IpcHandler {
        function setWallpaper(path: string): void {
            root.setWallpaper(path);
        }

        function setScheme(scheme: string): void {
            root.setScheme(scheme);
        }

        function setFromWallpaper(enabled: bool): void {
            root.setFromWallpaper(enabled);
        }

        function regenerate(): void {
            root.regenerate();
        }

        function status(): string {
            return root.status();
        }

        target: "theme"
    }
}
