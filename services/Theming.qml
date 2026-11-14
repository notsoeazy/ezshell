pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme
import qs.services

// Makes a Material palette from the wallpaper with matugen, writes it where
// Theme reads it, and colours other programs from it: terminals, Hyprland,
// GTK, and any template the user provides. matugen only produces the
// palette; every file is filled in here.
Scope {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || `${home}/.config`
    // Where the palette and everything made from it are written.
    readonly property string dir: Theme.path.slice(0, Theme.path.lastIndexOf("/"))
    readonly property string templateDir: `${configHome}/ezshell/templates`
    // The last palette made: { wallpaper, variant, light: {...}, dark: {...} }.
    property var palette: null
    // The colours of the appearance in use, for everything written out.
    readonly property var colours: palette ? (Config.appearance.dark ? palette.dark : palette.light) : null
    // The ANSI hues in terminal order, 1 to 6: red, green, yellow, blue,
    // magenta, cyan, in degrees.
    readonly property list<int> ansiHues: [0, 120, 50, 220, 300, 180]

    function generate(): void {
        if (!Config.theming.dynamic || Wallpapers.current.length === 0)
            return;

        if (matugen.running)
            again = true;
        else
            matugen.running = true;
    }

    // Asked for while matugen was already running.
    property bool again

    // matugen's JSON: colors.<role_name>.<light|dark>.color.
    function build(text: string): void {
        let data;
        try {
            data = JSON.parse(text);
        } catch (error) {
            console.warn("Theming: matugen gave no palette; the colours stay as they are");
            return;
        }

        const result = {
            wallpaper: Wallpapers.current,
            variant: Config.theming.variant,
            light: {},
            dark: {}
        };
        for (const [role, modes] of Object.entries(data.colors ?? {})) {
            const name = role.replace(/_(.)/g, (match, letter) => letter.toUpperCase());
            result.light[name] = modes.light.color;
            result.dark[name] = modes.dark.color;
        }
        addTerminal(result.light, false);
        addTerminal(result.dark, true);

        palette = result;
        const json = JSON.stringify(result, null, 2);
        // Theme reads the file when it changes; handing it over as well
        // covers the first run, before the file exists.
        Theme.load(json);
        write(Theme.path, json);
    }

    // The sixteen terminal colours: greys from the palette, and the six
    // hues pulled a little toward the accent so they belong to it.
    function addTerminal(colours: var, dark: bool): void {
        const accent = Qt.color(colours.primary);
        const accentHue = accent.hslHue < 0 ? 0 : accent.hslHue * 360;
        for (let i = 0; i < ansiHues.length; i++) {
            const difference = ((accentHue - ansiHues[i] + 540) % 360) - 180;
            const hue = ((ansiHues[i] + Math.max(-15, Math.min(15, difference / 2)) + 360) % 360) / 360;
            colours[`term${i + 1}`] = Qt.hsla(hue, dark ? 0.55 : 0.6, dark ? 0.72 : 0.38, 1).toString();
            colours[`term${i + 9}`] = Qt.hsla(hue, dark ? 0.7 : 0.65, dark ? 0.82 : 0.46, 1).toString();
        }
        colours.term0 = dark ? colours.surfaceContainerHighest : colours.onSurface;
        colours.term7 = colours.onSurfaceVariant;
        colours.term8 = colours.outline;
        colours.term15 = dark ? colours.onSurface : colours.surfaceContainerHighest;
    }

    // Colour the other programs, each only if it is turned on.
    function publish(): void {
        if (!colours || !Config.theming.dynamic)
            return;

        if (Config.theming.terminal) {
            write(`${dir}/sequences.txt`, sequences());
            // Open terminals take the colours at once; new ones should
            // `cat` the file from the shell's startup file.
            Quickshell.execDetached(["sh", "-c", 'sleep 0.2; for t in /dev/pts/[0-9]*; do [ -w "$t" ] && timeout 1 sh -c \'cat "$0" > "$1"\' "$0" "$t"; done', `${dir}/sequences.txt`]);
        }
        if (Config.theming.hyprland)
            write(`${configHome}/hypr/scheme/current.lua`, lua());
        if (Config.theming.gtk) {
            const css = fill(gtkTemplate.text());
            write(`${configHome}/gtk-3.0/gtk.css`, css);
            write(`${configHome}/gtk-4.0/gtk.css`, css);
        }
        if (Config.theming.templates)
            templates.running = true;
    }

    // Escape sequences that set a terminal's colours: foreground,
    // background, cursor, selection, then the sixteen.
    function sequences(): string {
        const set = (colour, ...codes) => `\x1b]${codes.join(";")};rgb:${colour.slice(1, 3)}/${colour.slice(3, 5)}/${colour.slice(5, 7)}\x1b\\`;
        let text = set(colours.onSurface, 10) + set(colours.surface, 11) + set(colours.secondary, 12) + set(colours.secondary, 17);
        for (let i = 0; i < 16; i++)
            text += set(colours[`term${i}`], 4, i);
        return text;
    }

    // A Lua table of every colour, without the "#", as Hyprland configs
    // written for Caelestia expect.
    function lua(): string {
        const lines = Object.entries(colours).map(([name, value]) => `  ${name} = "${value.slice(1)}",`);
        return `return {\n${lines.join("\n")}\n}\n`;
    }

    // Fill in a template: {{ $role }} is "#rrggbb", {{ $role.strip }} is
    // "rrggbb", and {{ $mode }} is "light" or "dark".
    function fill(template: string): string {
        return template.replace(/\{\{\s*\$(\w+)(\.strip)?\s*\}\}/g, (match, name, strip) => {
            if (name === "mode")
                return Config.appearance.dark ? "dark" : "light";
            const value = colours[name];
            if (value === undefined)
                return match;
            return strip ? value.slice(1) : value;
        });
    }

    // Write a file in one step, so nothing reads half of it.
    function write(path: string, text: string): void {
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf %s "$2" > "$1.tmp" && mv "$1.tmp" "$1"', "sh", path, text]);
    }

    onColoursChanged: publish()
    Component.onCompleted: generate()

    Connections {
        function onCurrentChanged(): void {
            root.generate();
        }

        target: Wallpapers
    }

    Connections {
        function onDynamicChanged(): void {
            root.generate();
        }

        function onVariantChanged(): void {
            root.generate();
        }

        function onTerminalChanged(): void {
            root.publish();
        }

        function onHyprlandChanged(): void {
            root.publish();
        }

        function onGtkChanged(): void {
            root.publish();
        }

        function onTemplatesChanged(): void {
            root.publish();
        }

        target: Config.theming
    }

    Process {
        id: matugen

        command: ["matugen", "image", Wallpapers.current, "--config", Quickshell.shellPath("assets/matugen.toml"), "--json", "hex", "--dry-run", "--quiet", "--prefer", "saturation", "--type", `scheme-${Config.theming.variant}`]
        onExited: code => {
            if (code !== 0)
                console.warn(`Theming: matugen exited with code ${code}; is it installed, and is "${Config.theming.variant}" one of its scheme types?`);
            if (root.again) {
                root.again = false;
                running = true;
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length > 0)
                    root.build(text);
            }
        }
    }

    FileView {
        id: gtkTemplate

        path: Quickshell.shellPath("assets/templates/gtk.css")
        blockLoading: true
    }

    // The user's templates: each file's name, a NUL, its text, a NUL.
    Process {
        id: templates

        command: ["sh", "-c", 'for f in "$1"/*; do [ -f "$f" ] && { printf "%s\\0" "${f##*/}"; cat "$f"; printf "\\0"; }; done', "sh", root.templateDir]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("\0");
                for (let i = 0; i + 1 < parts.length; i += 2)
                    root.write(`${root.dir}/${parts[i]}`, root.fill(parts[i + 1]));
            }
        }
    }
}
