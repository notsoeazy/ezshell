pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.utils

// Turns the wallpaper or preset into theme.json, which themes/Colors.qml reads (this service never touches Colors).
// One matugen Process serves previews, wallpaper themes and external app templates. Always the dark variant:
// the island is black, and the shell has no light mode. Without matugen, one warning and the palette stays as it is.
Singleton {
    id: root

    readonly property string file: `${Paths.state}/theme.json`
    readonly property string matugenConfig: `${Paths.state}/matugen.toml`
    // "wallpaper" or "palette" for what was last written; "" before the first write this session.
    readonly property string source: internal.source
    // Role map from the last preview run (settings app), or null.
    readonly property var preview: internal.preview
    readonly property string error: internal.error
    // Contrast fixes applied to the last generated palette, e.g. "primaryFg on primary 3.9 → 4.6".
    readonly property list<string> fixes: internal.fixes
    readonly property list<string> schemes: Matugen.schemes
    readonly property list<string> presets: Palettes.names

    // Writes what the config asks for: the wallpaper's palette, or the chosen built-in preset.
    function regenerate(): void {
        if (Config.theme.fromWallpaper && Config.wallpaper.path !== "") {
            root.run(Config.wallpaper.path, Config.theme.scheme, "apply");
        } else {
            const palette = Palettes.get(Config.theme.preset);
            internal.fixes = [];
            root.write(palette, "palette");
            if (Config.theme.kitty)
                root.runApps(palette.primary);
        }
    }

    function previewWallpaper(path: string, scheme: string): void {
        root.run(Paths.expand(path), scheme, "preview");
    }

    function setWallpaper(path: string): void {
        Wallpapers.set(path);
    }

    function setScheme(scheme: string): void {
        if (root.schemes.includes(scheme))
            Config.theme.scheme = scheme;
        else
            console.warn(`[theme] unknown scheme ${scheme}`);
    }

    function setPreset(name: string): void {
        if (!root.presets.includes(name)) {
            console.warn(`[theme] unknown preset ${name}`);
            return;
        }
        Config.theme.preset = name;
        Config.theme.fromWallpaper = false;
    }

    function setFromWallpaper(enabled: bool): void {
        Config.theme.fromWallpaper = enabled;
    }

    function setRadiusScale(scale: real): void {
        Config.theme.radiusScale = Math.max(0, Math.min(2, Math.round(scale * 100) / 100));
    }

    function setCardOpacity(opacity: real): void {
        Config.theme.cardOpacity = Math.max(0.4, Math.min(1, Math.round(opacity * 100) / 100));
    }

    function setKitty(enabled: bool): void {
        Config.theme.kitty = enabled;
    }

    function run(path: string, scheme: string, purpose: string): void {
        internal.purpose = purpose;
        internal.error = "";
        const base = Palettes.get(Config.theme.preset);
        const applyApps = purpose === "apply" && Config.theme.kitty;
        if (applyApps) {
            configWriter.setText(Matugen.configToml(Paths.state, true));
            configWriter.waitForJob();
        }
        // --prefer: matugen otherwise asks which source color to use; --fallback-color: images without a
        // usable color get the active preset's primary.
        const args = ["matugen", "image", path, "--json", "hex", "-m", "dark", "-t", scheme];
        args.push("--prefer", "saturation", "--fallback-color", base.primary);
        if (applyApps)
            args.push("-c", root.matugenConfig);
        else
            args.push("--dry-run");
        matugen.exec(args);
    }

    // Runs matugen templates from the preset's primary color when wallpaper theming is off.
    function runApps(hex: string): void {
        internal.purpose = "apps";
        internal.error = "";
        configWriter.setText(Matugen.configToml(Paths.state, true));
        configWriter.waitForJob();
        matugen.exec(["matugen", "color", "hex", hex, "-m", "dark", "-t", Config.theme.scheme, "-c", root.matugenConfig]);
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
        const preset = `preset (${Config.theme.preset})`;
        const using = Config.theme.fromWallpaper ? wallpaper : preset;
        const style = `radiusScale=${Config.theme.radiusScale}, cardOpacity=${Config.theme.cardOpacity}`;
        const apps = `kitty=${Config.theme.kitty ? "on" : "off"}`;
        const fixes = root.fixes.length > 0 ? `; contrast fixes: ${root.fixes.join("; ")}` : "";
        return `${using}; ${style}; ${apps}${root.error !== "" ? `; error: ${root.error}` : ""}${fixes}`;
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
                if (text.trim() === "" || internal.purpose === "apps")
                    return;
                try {
                    const base = Palettes.get(Config.theme.preset);
                    const palette = root.fit(Matugen.toPalette(JSON.parse(text), base));
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

    FileView {
        id: configWriter

        path: root.matugenConfig
        atomicWrites: true
    }

    // Wallpaper, scheme, preset or the switch changed (settings app, IPC, a hand edit): rebuild the theme.
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

        function onPresetChanged(): void {
            Qt.callLater(root.regenerate);
        }

        function onKittyChanged(): void {
            if (Config.theme.kitty)
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

        function setPreset(name: string): void {
            root.setPreset(name);
        }

        function setFromWallpaper(enabled: bool): void {
            root.setFromWallpaper(enabled);
        }

        function setRadiusScale(scale: real): void {
            root.setRadiusScale(scale);
        }

        function setCardOpacity(opacity: real): void {
            root.setCardOpacity(opacity);
        }

        function setKitty(enabled: bool): void {
            root.setKitty(enabled);
        }

        function regenerate(): void {
            root.regenerate();
        }

        function presets(): string {
            return root.presets.join("\n");
        }

        function status(): string {
            return root.status();
        }

        target: "theme"
    }
}
