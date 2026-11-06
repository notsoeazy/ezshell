# ezshell — System Design & Rulebook

Nov 6, 2026 · **Status: phases 1–6 and E1–E6 done.** New features are planned in `docs/ROADMAP.md`. This file stays the rulebook.

## Goals and principles

Build a pure-QML shell on Quickshell 0.3.2 or later. Each piece of system state lives in exactly one service. All user choices live in one JSON file in `~/.config/ezshell/`. UI polish and the dynamic island come after every feature works.

1. **Functional before pretty.** Every feature first ships as a service plus an IPC command that works from a terminal. UI is added on top.
2. **Native first.** Use Quickshell's own modules (Pipewire, Mpris, Networking, Bluetooth, UPower, Notifications, Hyprland). Shell out only for gaps: brightness and night light.
3. **One source of truth.** System state lives in `services/`, user settings in `Config`, and visual values in `Appearance` and `Colors`. Nothing else stores state.
4. **Data down, intent up.** Services push data into modules, and modules pass it to components. User actions travel back up as function calls on a service.
5. **No C++ plugin, no companion CLI, no Python daemon.** Any helper script lives in `scripts/` and is called by exactly one service.
6. **Small files.** Aim for 150 lines per file and hard-split at 250. Comment only to explain *why*.

## What we learned from other shells

The structure and icon system come from caelestia, the island animation from hyprism, and the config pattern from end-4. We avoid all three projects' heavy machinery.

The repositories were cloned on 2026-11-05: caelestia shell at commit bcbb5d5, hyprism at a545398, and Quickshell at the v0.3.2 tree.

| Source | Adopt | Avoid |
| --- | --- | --- |
| [Quickshell docs](https://quickshell.org/docs/v0.3.2/guide/) | `qs.*` root imports with no qmldir, `Singleton` services, `FileView` + `JsonAdapter`, `LazyLoader` for windows, `IpcHandler` | Hand-written `qmldir` files, `root:/` imports, `Variants` inside `LazyLoader` (it blocks) |
| [caelestia](https://github.com/caelestia-dots/shell) | `services/ modules/ components/ utils/` layout, `MaterialIcon` with size presets and FILL/GRAD axes, `Anim` with token durations, `PersistentProperties` visibility state, `offsetScale` → `Loader` open/close pattern, special workspaces shown generically from `special:*` | The C++ plugin, logic split across the shell, a Python CLI and Lua dots, the 1,800-line `nmcli` parser, one fullscreen masked window with an SDF blob background |
| [hyprism](https://github.com/kristyancarvalho/hyprism) | One `mode` string with a whitelist, a `{width, height, radius}` table per mode, a single-`progress` morph animation that survives interruption, an exclusion window paired with an overlay window, a focus-grab grace timer | The Python polling daemon, the 950-line controller, threading `controller` and `theme` through as properties, ternary `Loader` chains, Nerd Font glyph maps |
| [end-4 (ii)](https://github.com/end-4/dots-hyprland) | Pure-QML `Config.qml` with debounced reload and write, and file creation on `FileNotFound` | Not studied in depth |

Noctalia was dropped from the study because it is now a native C++ shell and no longer uses Quickshell.

## Directory structure and placement

Keep your skeleton and add two directories: `config/` for settings and paths, and `state/` for UI state such as which panel is open. Every directory name becomes an import path: `services/` is `import qs.services`.

```
shell.qml              entry: ShellRoot, instantiates modules, nothing else
config/
  Config.qml           settings singleton (FileView + JsonAdapter)
  Paths.qml            resolves ~/.config/ezshell, state and cache dirs
themes/
  Appearance.qml       static tokens: spacing, rounding, font sizes, animation
  Colors.qml           palette, read from ~/.local/state/ezshell/theme.json (the Theme service writes it)
state/
  Visibility.qml       which panel / island section / temporary mode is open, and where
services/              one singleton per system domain
  Time.qml Audio.qml Players.qml Brightness.qml NightLight.qml
  Wifi.qml Bt.qml Notifs.qml Battery.qml Hypr.qml Tray.qml Apps.qml
components/            stateless UI primitives
  StyledText.qml StyledRect.qml MaterialIcon.qml Anim.qml CAnim.qml ...
modules/               one folder per feature, entry file named after it
  island/Island.qml    the island: resting pill, temporary modes (OSD, mic, banner, music), expanded sections
  launcher/Launcher.qml  lockscreen/Lockscreen.qml  wallpaper/Wallpaper.qml  settings/Settings.qml
utils/                 pure-function QML singletons (Icons.qml); qs.<dir> modules don't export .js files
scripts/               non-QML helpers, run only by services
assets/                images, svg, bundled fonts
```

**Where does it go?** Work down the list and stop at the first match.

1. It observes or changes system state (D-Bus, Pipewire, sockets, processes, sysfs) → `services/<Domain>.qml`, a singleton.
2. It is a user setting → a key in the `Config` adapter, never a property on a service.
3. It is a visual constant → `themes/Appearance.qml`. A color → `themes/Colors.qml`.
4. It records which UI is open → `state/Visibility.qml`.
5. It is UI used by two or more modules, or generic by nature (icon, slider, toggle) → `components/`.
6. It is UI used by one feature → `modules/<feature>/`, even if it looks generic.
7. It is a pure function (format time, clamp, fuzzy match) → `utils/`.
8. It is shell or Python → `scripts/`, called as `["sh", Quickshell.shellPath("scripts/x.sh")]`.

**Naming**

- `.qml` files are PascalCase, with one root type per file. The filename is the type name.
- Singletons are short domain nouns with no `Service` suffix.
- **Never reuse a Quickshell singleton's name.** `Bluetooth`, `Pipewire`, `Mpris`, `Networking`, `Hyprland` and `UPower` are taken, which is why the services are named `Bt`, `Audio`, `Players`, `Wifi`, `Hypr` and `Battery`.
- Inside a module, the entry file carries the module's name and internal parts get role names: `Content.qml`, `Wrapper.qml`, `Row.qml`.
- The root object's id is always `root`. Other ids name a role (`slider`), not a type (`rectangle1`).

**When to split a file and when not to**

- Split when a child subtree has its own state or runs over 40 lines, when a delegate is written inline, or when a file mixes data and presentation.
- Don't create a file for something used once and under about 30 lines.
- Don't create wrappers that only forward properties.
- Don't create a service for a fire-and-forget command. Call `Quickshell.execDetached([...])` instead.

## Layering rules

Imports only point downward. A service never knows a module exists, and a component never knows where its data comes from. Always import with `import qs.<dir>`, never with relative paths; the Quickshell docs call module imports more LSP-friendly.

| Layer | May import | Must never import |
| --- | --- | --- |
| `shell.qml` | modules, config | services (except the startup force-load line) |
| `modules/*` | components, services, state, config, themes, utils | another module |
| `components/` | themes, utils, other components | services, modules, state, config |
| `state/` | config | services, modules, components |
| `services/` | config, utils, other services (acyclic), `Quickshell.*` | modules, components, themes, state |
| `config/`, `themes/` | `Quickshell.*`, utils | everything else |
| `utils/` | nothing | everything |

- **Two modules need the same thing?** Move it into a component (UI) or a service (data). Modules never talk to each other directly. They both read `Visibility` instead.
- **Two services need each other?** Merge them, or extract the shared part into a third service.
- **A component needs a setting?** Pass it in as a property from the module. Components take data through properties (`required` when there is no sensible default) and report through signals.
- **Theming stays decoupled.** `Colors` reads a file. Whatever writes that file (matugen, a script, the wallpaper service) never touches `Colors` directly.

## Component hierarchy

`shell.qml` instantiates each module once. Each module owns its windows, either one per screen through `Variants` or on demand through `LazyLoader`. Modules display state from services, config, themes and `Visibility`, and draw everything with `components/`.

```
Inputs        Keybinds / terminal (qs ipc call, GlobalShortcut)
              System (Pipewire, NM, BlueZ, MPRIS, Hyprland, CLIs)
              ~/.config/ezshell/config.json, ~/.local/state/ezshell/theme.json
                 │ IPC / events / file watch
State layer   state/Visibility   services/   config/Config   themes/
                 │ bind state ↓   call functions ↑
Modules       Per screen (Variants):   island (Top; Overlay while elevated) + its exclusion window,
                                       wallpaper (Background)
              On demand (LazyLoader):  launcher, settings
              Session:                 lockscreen (WlSessionLock + PAM)
                 │
Components    StyledText, StyledRect, MaterialIcon, Anim, CAnim
```

Read the diagram top to bottom. Inputs reach services and `Visibility` over IPC. Modules bind to that state and call service functions back. Components never see a service.

**Windows**

- Use one `PanelWindow` per panel per screen, not caelestia's single fullscreen masked window. Every panel stays independent and easy to debug.
- Assign layers through `WlrLayershell.layer`: wallpaper on `Background`, the island on `Top` (moving to `Overlay` only while elevated, see ISLAND.md "Motion").
- The OSD, mic indicator, notification banners and compact music are **modes of the island**, not separate windows.
- The island uses hyprism's pair of windows: an invisible window that only reserves space, plus an island window sized to the largest mode with `mask: Region { item: surface }`. Expanding never moves other windows.
- The launcher uses `WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand` plus a `HyprlandFocusGrab`, so clicking outside closes it.
- Give each window a `WlrLayershell.namespace` such as `ezshell-island`, so Hyprland `layerrule`s can target it (blur, animations).

**`shell.qml`**: the whole file once phase 6 is done. `Settings {}` joins in enhancement E1.

```qml
import Quickshell
import qs.services
import qs.modules.island
import qs.modules.launcher
import qs.modules.lockscreen
import qs.modules.wallpaper

ShellRoot {
    Component.onCompleted: { Notifs; Idle; Brightness; }

    Wallpaper {}
    Island {}
    Launcher {}
    Lockscreen {}
}
```

**A per-screen module**, in its simplest form. The real `modules/island/Island.qml` adds the exclusion window and `Transients` (see ISLAND.md "Files").

```qml
import Quickshell
import Quickshell.Wayland

Variants {
    model: Quickshell.screens

    PanelWindow {
        required property ShellScreen modelData

        screen: modelData
        anchors { top: true; left: true; right: true }
        implicitHeight: bar.implicitHeight
        color: "transparent"
        WlrLayershell.namespace: "ezshell-bar"

        Bar { id: bar; anchors.fill: parent }
    }
}
```

**`state/Visibility.qml`**: one open panel at a time, on one screen. The minimal version is below. The island adds `temporary`, `stack`, `open`, `back` and the section-aware `toggle` described in ISLAND.md "State and IPC".

```qml
pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root

    property string panel: ""
    property string screen: ""

    function toggle(name: string): void {
        screen = Hyprland.focusedMonitor?.name ?? "";
        panel = panel === name ? "" : name;
    }

    IpcHandler {
        function toggle(name: string): void { root.toggle(name); }
        function close(): void { root.panel = ""; }

        target: "panels"
    }
}
```

An on-demand module then reads it directly, for example `LazyLoader { active: Visibility.panel === "launcher"; PanelWindow { … } }`.

Short island modes (OSD, mic, banner, compact music) are triggered by `modules/island/Transients.qml`, not by the services:
- It listens to the services itself, for example `Connections { target: Brightness; function onLevelChanged() { … } }`.
- It sets `Visibility.temporary` and clears it after `Config.osd.hideDelay`.

This keeps services free of any knowledge of UI.

## Config system

One file, `~/.config/ezshell/config.json`, is both read and written by a single `Config` singleton built on `FileView` + `JsonAdapter`. The defaults are the adapter's property initialisers, so they exist in exactly one place.

**How it behaves**

- **Read.** `watchChanges: true` plus a 50 ms debounced `reload()`, so hand edits apply live.
- **Write.** Any assignment such as `Config.nightLight.enabled = true` fires `adapterUpdated`, which triggers a 50 ms debounced `writeAdapter()`. Writes are atomic by default.
- **First run.** On `FileViewError.FileNotFound` it calls `writeAdapter()`. The file is created with every default, and missing parent directories are created too.
- **Structure.** One `JsonObject` per feature, so the file reads like the shell's feature list.

`config/Paths.qml`

```qml
pragma Singleton

import Quickshell

Singleton {
    readonly property string config: `${Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"}/ezshell`
    readonly property string state: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/ezshell`
}
```

`config/Config.qml`

```qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property alias bar: adapter.bar
    readonly property alias osd: adapter.osd
    readonly property alias audio: adapter.audio
    readonly property alias brightness: adapter.brightness
    readonly property alias nightLight: adapter.nightLight
    readonly property alias workspaces: adapter.workspaces
    readonly property alias wallpaper: adapter.wallpaper

    FileView {
        id: fileView

        path: `${Paths.config}/config.json`
        watchChanges: true
        onFileChanged: reloadTimer.restart()
        onAdapterUpdated: writeTimer.restart()
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter(); }

        JsonAdapter {
            id: adapter

            property JsonObject bar: JsonObject { property bool showSeconds: false }
            property JsonObject osd: JsonObject { property int hideDelay: 1500 }
            property JsonObject audio: JsonObject { property real step: 0.05 }
            property JsonObject brightness: JsonObject { property real step: 0.05 }
            property JsonObject nightLight: JsonObject {
                property bool enabled: false
                property int temperature: 4000
            }
            property JsonObject workspaces: JsonObject {
                property int shown: 5
                property list<var> special: [
                    { name: "music", icon: "music_note", exec: "spotify" },
                    { name: "term", icon: "terminal", exec: "kitty" }
                ]
            }
            property JsonObject wallpaper: JsonObject { property string path: "" }
        }
    }

    Timer { id: reloadTimer; interval: 50; onTriggered: fileView.reload() }
    Timer { id: writeTimer; interval: 50; onTriggered: fileView.writeAdapter() }
}
```

The resulting file:

```json
{
  "bar": { "showSeconds": false },
  "nightLight": { "enabled": false, "temperature": 4000 },
  "workspaces": {
    "shown": 5,
    "special": [
      { "name": "music", "icon": "music_note", "exec": "spotify" },
      { "name": "term", "icon": "terminal", "exec": "kitty" }
    ]
  }
}
```

**Rules for config**

- Each setting has exactly one key, and its default lives only in the adapter.
- Services and modules read `Config.<feature>.<key>`. Only the settings module and IPC handlers write to it.
- Store user *choices* here (step sizes, enabled flags, special workspaces). Store live *state* (current volume, connected network) in services, never in config.
- `writeAdapter()` writes every key, defaults included. That is fine for one personal file, and it makes the file self-documenting.
- The file lives outside the shell directory, so editing it never triggers a QML hot reload.

## Theme, tokens and icons

The look is split into two singletons, and every visual value comes from one of them:

- `Appearance` holds static design tokens you edit by hand.
- `Colors` holds a palette read from `~/.local/state/ezshell/theme.json` (generated state, kept out of the dotfiles).

The `Theme` service is the only writer of `theme.json`; `Colors` just reads it, so theming needs no QML changes in the UI.

**`themes/Appearance.qml`**: plain nested `QtObject`s, no file IO. This follows end-4's single-singleton model rather than caelestia's C++ tokens.

```qml
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property QtObject spacing: QtObject {
        readonly property int small: 4
        readonly property int normal: 8
        readonly property int large: 16
    }
    readonly property QtObject rounding: QtObject {
        readonly property int small: 8
        readonly property int normal: 16
        readonly property int full: 1000
    }
    readonly property QtObject font: QtObject {
        readonly property string family: "Google Sans Flex"
        readonly property string icons: "Material Symbols Rounded"
        readonly property QtObject size: QtObject {
            readonly property int small: 11
            readonly property int normal: 13
            readonly property int large: 16
            readonly property int icon: 18
        }
    }
    readonly property QtObject anim: QtObject {
        readonly property int fast: 150
        readonly property int normal: 250
        readonly property int slow: 400
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> emphasized: [0.05, 0.7, 0.1, 1, 1, 1]
    }
}
```

**`themes/Colors.qml`**: a `FileView` + `JsonAdapter` with Material 3 role names. The adapter's defaults are the built-in palette (`utils/Palettes.qml`: black surfaces with Nord blue accents); on first run, a missing `theme.json` is created with them (`onLoadFailed` → `writeAdapter()`, plus `onSaved` → reload so the watcher attaches). After that the shell never writes it, and `watchChanges` makes a regenerated file apply instantly. It has the same shape as the `Config` singleton, with `surface`, `surfaceFg`, `primary`, `primaryFg`, `surfaceContainer`, `outline`, `error` and so on as `property color` keys. Material 3's `onX` roles are named `xFg`, because QML rejects declared properties that start with `on` plus a capital letter. `Colors` resolves its own path, because `themes/` may not import `config/`.

**Dynamic theme (E6).** `services/Theme.qml` owns one `Process` that runs `matugen image <path> --json hex --dry-run -m dark -t <scheme> --prefer saturation`. It maps matugen's roles to ours (`onX` → `xFg`), forces `surface` to black, checks the main pairs against WCAG (4.5 for text, 3 for accents; `utils/Contrast.qml`) and tints any failing foreground toward white or black, then writes `theme.json` atomically. It runs when `Config.wallpaper.path`, `Config.theme.fromWallpaper` or `Config.theme.scheme` changes. With theming off, or no wallpaper, it writes the built-in palette. Dark mode only: the island is always black. A preview run fills `Theme.preview` without writing, for the settings page. If matugen is missing, it logs one warning and keeps the current palette.

**Icons.** Install `ttf-material-symbols-variable` as a system font. This is the package caelestia lists. Every icon in the shell is drawn through one component, which takes a ligature name such as `text: "wifi"`.

`components/MaterialIcon.qml`

```qml
import QtQuick
import qs.themes

StyledText {
    property real fill: 0
    property int size: Appearance.font.size.icon

    font.family: Appearance.font.icons
    font.pixelSize: size
    font.variableAxes: ({ FILL: Math.round(fill * 10) / 10, opsz: size })
}
```

- Round `fill` to one decimal and never animate it continuously. Each distinct axis value creates a new font instance, and end-4 flags this as leaky.
- `font.variableAxes` needs Qt 6.7 or later, which Arch already ships.
- Add an icon name map in `utils/Icons.qml` only if the same name→icon logic appears in two places, for example battery level to icon.

**Other primitives (`components/`)**

- `StyledText`: a `Text` with color `Colors.surfaceFg`, `Appearance.font.family`, and `Behavior on color { CAnim {} }`.
- `StyledRect`: a `Rectangle` with a transparent default color and an animated color.
- `Anim`: a `NumberAnimation` with `duration: Appearance.anim.normal`, `easing.type: Easing.BezierSpline` and `easing.bezierCurve: Appearance.anim.standard`. Every `Behavior` uses `Anim {}`, never a raw duration.
- `CAnim`: the same as `Anim`, but for `ColorAnimation`.

## Services

Only two features need external tools: brightness and night light. Everything else uses an event-driven Quickshell module, so the shell has almost no polling.

| Feature | Service | Backend | System dependency | Notes |
| --- | --- | --- | --- | --- |
| Volume, mic | `Audio` | `Quickshell.Services.Pipewire` | pipewire | Bind the sink and source with `PwObjectTracker`, or `volume` stays invalid |
| Media | `Players` | `Quickshell.Services.Mpris` | — | `position` doesn't notify; tick a `Timer` only while playing |
| Brightness | `Brightness` | `Process`: `brightnessctl`, `ddcutil` | brightnessctl, ddcutil | Re-read after each write; no polling |
| Night light | `NightLight` | `execDetached` → `hyprctl hyprsunset temperature N` / `identity` | hyprsunset (`exec-once`) | Shell keeps on/off and temperature in `Config` |
| Wi‑Fi | `Wifi` | `Quickshell.Networking` (0.3+) | NetworkManager | Replaces nmcli scraping: `connectWithPsk`, `wifiEnabled` |
| Bluetooth | `Bt` | `Quickshell.Bluetooth` | bluez | PIN or passkey pairing support unconfirmed |
| Notifications | `Notifs` | `NotificationServer` | — | Set `tracked = true` in `onNotification`, else it is dropped |
| Battery, power | `Battery` | `Quickshell.Services.UPower` | upower | `PowerProfiles` is in the same module |
| Workspaces | `Hypr` | `Quickshell.Hyprland` | — | Also owns special workspaces |
| Tray | `Tray` | `Quickshell.Services.SystemTray` | — | Menus through `QsMenuOpener` |
| Clock | `Time` | `SystemClock` | — | Use `precision: SystemClock.Minutes` unless seconds are shown |
| Apps | `Apps` | `DesktopEntries` + `ScriptModel` | — | Launcher data source |
| Wallpaper | `Wallpapers` | `Config.wallpaper.*` + one `find` over the folder and its subfolders; drawn by a Background-layer window | — | No swww or hyprpaper needed; two-image cross-fade, slideshow timer |
| Lock | (module) | `WlSessionLock` + `Quickshell.Services.Pam` | pam | Keep it simple; if the shell crashes while locked, the screen stays locked |
| Idle | `Idle` | `IdleMonitor`, `IdleInhibitor` | — | Lock or DPMS after timeouts from `Config` |
| Theme | `Theme` | `Process` (matugen) + `FileView` writer | matugen | Writes `theme.json`; dark only, contrast-checked |

**What every service looks like**

- It is a `Singleton` root, exposes `readonly property` state bound to the native object, and offers verb functions: `set`, `toggle`, `up`, `down`, `next`.
- It holds its own `IpcHandler` whose target is the service name in lowercase. Every feature is therefore controllable from a keybind before any UI exists.
- It owns every `Process` for its domain. Use one long-running process with a `SplitParser` for streams, and `StdioCollector` for one-shot reads. Never create a process per widget.
- It checks `exitCode` when the result matters, guards optional objects with `?.` and `??`, and logs with `console.warn("[brightness] …")`.
- Services that must run at startup (`Notifs`, `Idle`, and any service with an `IpcHandler` you want live) are force-loaded in `shell.qml`: `Component.onCompleted: { Notifs; Idle; Brightness; }`. Singletons are otherwise created lazily on first access.

## Special workspaces

Adding a special workspace takes one JSON entry and one Hyprland bind. Caelestia splits this across Lua dots and a CLI; here the shell owns the list, launches the app on first toggle, and shows the icon.

**1. Declare it in `config.json`**

```json
"workspaces": {
  "special": [
    { "name": "music", "icon": "music_note", "exec": "spotify" },
    { "name": "notes", "icon": "edit_note", "exec": "obsidian" }
  ]
}
```

**2. Bind a key in `hyprland.conf`** (or, with a Lua config, `hl.bind("SUPER + M", hl.dsp.exec_cmd("qs -c ezshell ipc call hypr toggleSpecial music"))`)

```
bind = SUPER, M, exec, qs -c ezshell ipc call hypr toggleSpecial music
bind = SUPER, N, exec, qs -c ezshell ipc call hypr toggleSpecial notes
```

Use `qs -p <path>` instead of `-c` if the shell doesn't live in `~/.config/quickshell/ezshell`.

**3. The service does the rest (`services/Hypr.qml`, excerpt)**

```qml
readonly property string activeSpecial: Hyprland.focusedMonitor?.lastIpcObject?.specialWorkspace?.name?.replace("special:", "") ?? ""

function toggleSpecial(name: string): void {
    const entry = Config.workspaces.special.find(w => w.name === name);
    const occupied = Hyprland.workspaces.values.some(w => w.name === `special:${name}` && w.toplevels.values.length > 0);
    if (!occupied && entry?.exec)
        Hyprland.dispatch(`exec [workspace special:${name}] ${entry.exec}`);
    else
        Hyprland.dispatch(`togglespecialworkspace ${name}`);
}

Connections {
    target: Hyprland
    function onRawEvent(event: HyprlandEvent): void {
        if (event.name === "activespecial") Hyprland.refreshMonitors();
    }
}

IpcHandler {
    target: "hypr"
    function toggleSpecial(name: string): void { root.toggleSpecial(name); }
}
```

The module uses a `Repeater` over `Config.workspaces.special`, with one `MaterialIcon` per entry. The icon is highlighted when `Hypr.activeSpecial === modelData.name` and dimmed when the workspace is empty.

**Optional: route apps that open by themselves.** A Hyprland window rule such as `windowrule = workspace special:music, class:^(Spotify)$` sends a window there even when you launch it elsewhere. Rule syntax differs between Hyprland versions and the Lua config (`Hyprland.usingLua`), so check the wiki for your version.

## IPC and keybinds

Every action goes through `IpcHandler`, so it can be tested from a terminal with `qs -c ezshell ipc call <target> <fn> [args]`. Use `GlobalShortcut` only where you need key press and release events, such as tap-Super for the launcher.

| Target | Lives in | Functions |
| --- | --- | --- |
| `audio` | `services/Audio.qml` | `up`, `down`, `set(real)`, `toggleMute`, `toggleMicMute`, `status`, `outputs`, `inputs`, `streams`, `setOutput(name)`, `setInput(name)`, `setStreamVolume(id, real)`, `setMic(real)`, `mic` |
| `brightness` | `services/Brightness.qml` | `up`, `down`, `set(real)` |
| `nightlight` | `services/NightLight.qml` | `toggle`, `setTemperature(int)` |
| `players` | `services/Players.qml` | `playPause`, `next`, `previous`, `status`, `list`, `select(identity)`, `seek(seconds)`, `position` |
| `hypr` | `services/Hypr.qml` | `toggleSpecial(string)`, `focus(int)`, `cycle(int)`, `screencast`, `simulateScreencast(bool)` |
| `notifs` | `services/Notifs.qml` | `clear`, `toggleDnd`, `setDnd(bool)`, `status`, `list` |
| `wifi` | `services/Wifi.qml` | `toggle`, `setEnabled(bool)`, `scan(bool)`, `connect(name, password)`, `disconnect`, `forget(name)`, `status`, `list`, `saved`, `refreshSaved`, `forgetSaved(uuid)`, `connectHidden(ssid, password)` |
| `bt` | `services/Bt.qml` | `toggle`, `setEnabled(bool)`, `scan(bool)`, `connect(addr)`, `disconnect(addr)`, `forget(addr)`, `status`, `list`, `paired` |
| `apps` | `services/Apps.qml` | `search(query)`, `launch(query)` |
| `idle` | `services/Idle.qml` | `toggleInhibit`, `setInhibited(bool)`, `status` |
| `session` | `services/Session.qml` | `lock`, `suspend`, `logout`, `reboot`, `poweroff` |
| `weather` | `services/Weather.qml` | `refresh`, `status`, `hourly` |
| `sysinfo` | `services/SysInfo.qml` | `status`, `setActive(bool)` |
| `camera` | `services/Camera.qml` | `status` |
| `theme` | `services/Theme.qml` | `setWallpaper(path)`, `setScheme(string)`, `setFromWallpaper(bool)`, `regenerate`, `status` |
| `wallpaper` | `services/Wallpapers.qml` | `set(path)`, `get`, `random`, `next`, `previous`, `list`, `rescan` |
| `battery` | `services/Battery.qml` | `status`, `simulate(real, bool)`, `reset`, `profile`, `setProfile(string)` |
| `launcher` | `state/Visibility.qml` | `open(prefix)`: the launcher with a provider prefix typed, e.g. `>` for actions (F2) |
| `panels` | `state/Visibility.qml` | `toggle(string)`, `open(name, arg)`, `close` (`open settings <page>` since E1); from E2 also `back`, from E3 `push(page)` (launcher, settings, island sections; see ISLAND.md) |
| `lock` | `modules/lockscreen/Lockscreen.qml` | `lock` |

**Rules**

- Name each target after its service in lowercase. Targets must be unique.
- Every IPC function has typed arguments and a return type (`: void`). Untyped functions are not registered. The allowed types are `string`, `int`, `bool`, `real` and `color`, with at most 10 arguments.
- An IPC function only delegates to the service's own function. It contains no logic.
- Run `qs -c ezshell ipc show` to list every target, so there is no need to keep a separate IPC document.

Example `hyprland.conf` block:

```
$qs = qs -c ezshell ipc call
bindel = , XF86AudioRaiseVolume, exec, $qs audio up
bindel = , XF86AudioLowerVolume, exec, $qs audio down
bindl  = , XF86AudioMute,        exec, $qs audio toggleMute
bindel = , XF86MonBrightnessUp,  exec, $qs brightness up
bindel = , XF86MonBrightnessDown, exec, $qs brightness down
bindl  = , XF86AudioPlay,        exec, $qs players playPause
bind   = SUPER, Space,           exec, $qs panels toggle launcher
bind   = SUPER, L,               exec, $qs lock lock
exec-once = hyprsunset
exec-once = qs -c ezshell
```

## Anatomy of a feature

Every feature is built in the same six steps, always in this order: service, config keys, IPC, UI, settings row, wire-up. A feature is "done" at step 3, because it already works from a keybind.

1. **Service.** `services/Brightness.qml`: state as `readonly property`, intent as functions, and its own `IpcHandler`.
2. **Config keys.** Add `brightness: JsonObject { property real step: 0.05 }` to the `Config` adapter. That is the only place the default exists.
3. **IPC and keybind.** Add `bindel = , XF86MonBrightnessUp, exec, $qs brightness up` and test it from a terminal.
4. **UI.** A part inside the module that shows it, such as the brightness row in `modules/island/OsdView.qml`, built from `components/` and bound to `Brightness.level`.
5. **Settings.** A row in `modules/settings/` that assigns `Config.brightness.step`. The adapter persists it.
6. **Wire-up.** Only for a brand-new module: one line in `shell.qml`.

`services/Brightness.qml`

```qml
pragma Singleton

import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    property real level

    function set(v: real): void {
        setter.exec(["brightnessctl", "-q", "set", `${Math.round(Math.max(0.01, Math.min(1, v)) * 100)}%`]);
    }

    Process {
        id: setter
        onExited: reader.running = true
    }

    Process {
        id: reader
        running: true
        command: ["brightnessctl", "-m", "info"]
        stdout: StdioCollector {
            onStreamFinished: root.level = parseInt(text.split(",")[3]) / 100
        }
    }

    IpcHandler {
        function up(): void { root.set(root.level + Config.brightness.step); }
        function down(): void { root.set(root.level - Config.brightness.step); }
        function set(v: real): void { root.set(v); }

        target: "brightness"
    }
}
```

A brightness row (illustrative; the real one lives in `modules/island/OsdView.qml`)

```qml
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.themes

RowLayout {
    spacing: Appearance.spacing.normal

    MaterialIcon {
        text: "brightness_6"
    }

    StyledSlider {
        Layout.fillWidth: true
        value: Brightness.level
        onMoved: Brightness.set(value)
    }
}
```

The two files show the pattern:

- The service never mentions the OSD, and the row never mentions `brightnessctl`.
- Every number comes from `Config` or `Appearance`.
- Each file has under 40 lines and no comments, because nothing in them is surprising.
- Supporting external monitors later (`ddcutil`) changes only the service file.

## Coding rules

Write the least QML that works. Use bindings over imperative code, tokens over numbers, and events over timers. Comment only when the *why* isn't obvious from the code.

**Attribute order.** This follows Qt's conventions, with a blank line between groups:

1. `id`
2. Property declarations: `required` first, then public, then `readonly` or derived, then `alias`
3. Signal declarations
4. Functions
5. Property assignments and handlers (`anchors`, `Layout.*`, `onX:`)
6. Child objects
7. `states` and `transitions` last

**Bindings and JavaScript**

- Prefer declarative bindings. Assign imperatively only inside an event handler or a service function. An assignment silently destroys the binding it replaces.
- A binding is one expression. Anything longer than about two lines becomes a typed function or a `readonly property` on the service.
- Derived state belongs in the service, such as `readonly property bool muted`, not recomputed in every widget.
- Type every property, parameter and return: `int`, `real`, `string`, `list<T>`. Use `var` only for raw JSON.
- Reach outer objects by id (`root.level`), never by unqualified lookup. Add `pragma ComponentBehavior: Bound` to files with delegates, and declare `required property var modelData` in each delegate.
- Write handler parameters explicitly: `onClicked: mouse => …`.

**Tokens, not magic numbers.** Every size, spacing, radius, duration, easing and color comes from `Appearance` or `Colors`. The only allowed literals are `0`, `1`, values that are part of the logic, and `true`/`false`. If a value is missing, add a token before you use it.

**Events before polling.** Use a native module first. If none fits, use a long-running `Process` with a `SplitParser`, a `Socket`, or a `FileView` with `watchChanges`. A `Timer` is a last resort, lives only in a service, and runs only while it is needed (`running: player.isPlaying`).

**Process**

- Processes live only in `services/`. Outside services, use only `Quickshell.execDetached([...])`.
- Pass arguments as a list. They don't go through a shell, so use `["sh", "-c", …]` only when you need pipes.
- Re-run a process with `exec()`, not by toggling `running`.

**Loading windows**

- Panels that start hidden (launcher, settings, power menu) go inside a `LazyLoader`, so closing one frees its memory.
- Use `Loader` for Items and `LazyLoader` for windows.
- Use `visible` only for cheap things that toggle often.
- Never put a `Variants` inside a `LazyLoader`.

**Comments**

- Comment *why*, never *what*. Comments are allowed for workarounds, tool quirks, units and ordering requirements.
- No banner comments, no commented-out code, and no header that repeats the filename.
- If a comment explains a name, rename the thing instead.

**Tooling**

- Put an empty `.qmlls.ini` next to `shell.qml`. Quickshell fills it in at runtime. Add it to `.gitignore`.
- Format with `/usr/lib/qt6/bin/qmlformat -i` (`/usr/bin/qmlformat` is Qt 5). Use `.qmlformat.ini` with only `IndentWidth=4`. In qmlformat 6.11, `MaxColumnWidth` and `SemicolonRule=essential` de-indent function bodies and corrupt template strings, so wrap long lines by hand. Do **not** enable `NormalizeOrder`, because it sorts attributes alphabetically and breaks the order above.
- Lint with `/usr/lib/qt6/bin/qmllint`, using the import paths from `.qmlls.ini` as caelestia's CI does. Ignore its "pragma Singleton without qmldir" warning, because Quickshell synthesises the qmldir.
- Add `//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1` at the top of `shell.qml` once the reload popup starts to annoy you.

**Pre-commit checklist**

- [ ] No module imports another module, and no service imports UI.
- [ ] No literal sizes, colors or durations.
- [ ] No new `Timer` where an event source exists, and no `Process` outside `services/`.
- [ ] Everything is typed, and files with delegates use `ComponentBehavior: Bound`.
- [ ] Each new setting has exactly one key, with its default in the `Config` adapter.
- [ ] Each new file is reused, over 40 lines, or its own concern. No pass-through wrappers.
- [ ] No file is over 250 lines.
- [ ] Hidden-by-default UI is lazy-loaded.
- [ ] Comments explain *why* only.
- [ ] `qmlformat` shows no diff, `qmllint` shows no new warnings, and the `qs` log is clean.

## Build plan

The work runs in six phases, each ending with something usable, followed by an enhancement stage. Phases 1 to 6 produce a fully functional shell. The enhancements add the expandable island, the dashboard, the settings app, polish and theming, all on top of the same services.

| Phase | Status |
| --- | --- |
| 1 Foundation | done |
| 2 Plain bar | done |
| 3 Controls and OSD | done |
| 4 Connectivity | done (its quick-settings UI is replaced in E2) |
| 5 Media and notifications | done (full media controls and notification list move to E3) |
| 6 Launcher, wallpaper, lockscreen, idle | done |
| E1 Settings app | done |
| E2 Expandable island | done |
| E3 Dashboard tabs | done (calendar events not yet: month grid only) |
| E4 Remaining island indicators | done |
| E5 Motion polish | done |
| E6 Theming | done (no templates for other apps yet) |

1. **Foundation.** Build `shell.qml`, `Paths`, `Config`, `Appearance`, `Colors` with default colors, `StyledText`, `StyledRect`, `MaterialIcon`, `Anim` and `CAnim`. Set up `.qmlls.ini`, qmlformat and qmllint.
   - Done when editing `config.json` changes the bar's clock format live.
2. **Plain bar (in `modules/island/`).** Use `Variants` over `Quickshell.screens`, one `PanelWindow` per screen anchored to the top, then add `Time`, `Hypr` workspaces with special workspaces, `Battery` and `Tray`.
   - Done when the special-workspace keybinds work end to end.
3. **Controls and OSD.** Add `Audio`, `Brightness` and `NightLight` with their IPC targets and media-key binds. The OSD is a temporary island mode (the morph was pulled forward from the original late-stage plan), shown when a service value changes, with a hide timer from `Config.osd.hideDelay`.
4. **Connectivity and quick settings.** Add `Wifi` and `Bt`, then a quick-settings popup from the bar for Wi‑Fi, Bluetooth, night light and volume, wrapped in a `LazyLoader` with a `HyprlandFocusGrab`.
5. **Media and notifications.** `Players` drives a media widget with controls. `Notifs` drives popups and a notification list with do-not-disturb.
   - Done so far: both services with IPC, the island's equalizer / unread badge / DND icon, the banner and compact-music modes. The full media controls (frame 04) and the notification list wait for the expanded island state.
6. **Launcher, wallpaper, lockscreen, idle.** Build the launcher from `Apps` and `ScriptModel` fuzzy search, a Background-layer wallpaper window, a `WlSessionLock` + PAM lockscreen, and `Idle`.
   - The functional shell is complete at this point.

**Enhancements, after phase 6, in order.** Each one is new UI on services that already exist. Read `docs/ISLAND.md` before E2–E5.

- **E1. Settings app.** A `FloatingWindow` in `modules/settings/`, opened with `panels toggle settings` or with a page name (`wifi`, `bluetooth`, `audio`, `power`, `workspaces`, `appearance`). It writes `Config`, and it is where the island's "… settings" links land.
  - Done: one file per page, a sidebar, and shared `Section` / `SettingRow`; generic `StyledButton`, `StyledSwitch`, `StyledTextField` and `StyledSlider` in `components/` for E2 to reuse.
  - Open state is `Visibility.settingsPage` (not `panel`), so the window stays open while the island changes. `panels open settings <page>` passes the page as the second argument.
  - Saved Wi‑Fi profiles and hidden SSIDs go through `nmcli` (Quickshell only lists in-range networks and can't join unseen ones); the hidden-network password goes through stdin.
  - Saved Wi‑Fi networks, hidden SSIDs, Bluetooth devices that need a PIN, idle timeouts, special-workspace editor.
- **E2. Expandable island.** Follow ISLAND.md "Expanding the island":
  - `Visibility.open/back/stack`, plus `open` and `back` on the `panels` IPC target;
  - clickable status icons that deep-link to their sections;
  - `Expanded.qml` with the `wifi`, `bluetooth`, `audio` and `power` sections, and a first `overview` holding the quick toggles;
  - focus and dismissal rules.
  - **Delete the phase 4 quick-settings popup** once its controls live in the island.
  - Done when clicking the Wi‑Fi icon opens the Wi‑Fi section, you can connect with a password, Esc steps back, and no window moves.
  - Built: `Visibility` stack/open/back, `Expanded.qml` with the overview quick toggles and the four sections, deep-link TapHandlers, focus and dismissal rules. New `Session` service (lock, suspend, log out, reboot, power off; IPC `session`); the lockscreen listens to `Session.lockRequested`, and `Idle` calls `Session.lock()`.
- **E3. Dashboard tabs.**
  - The full Overview bento (frame 14), plus the Media, System and Calendar tabs (frame 15).
  - New `Weather` and `SysInfo` services. `SysInfo` polls only while a dashboard tab is open.
  - The full media controls (frame 04) and the notification list move here from phase 5.
  - Built: `Weather` (Open-Meteo, no key; location from Config or the IP via ip-api.com, Manila fallback), `SysInfo` (/proc and /sys via FileView, `df`, `nvidia-smi` only while the GPU is awake; samples only while Overview or System is open), `Players` position/seek/picker. The Overview bento, Media, System and Calendar tabs, and the notification list (`panels push notifications`).
  - Calendar events: not built. The simplest source is `khal list` (run by a `Calendar` service through `Process`) with `vdirsyncer` syncing CalDAV/Google; reading `.ics` files directly needs an ICS parser with recurrence (RRULE) support in QML.
- **E4. Remaining island variations** from the v3 sheet: recording / screen share and mic/camera indicators, once a data source is confirmed (ISLAND.md "Default island variations").
  - Done. Mic: PipeWire links from a mic device into an app stream (`Audio.micInUse`, `micApps`). Camera: PipeWire links from a v4l2/libcamera node, plus open/close events on `/dev/video*` (`scripts/camera-watch.sh`, inotify) for apps that skip PipeWire (`Camera` service). Screen capture: Hyprland's `screencast` event (`Hypr.screenSharing`); recorders that read the GPU directly (gpu-screen-recorder `-w screen`) aren't seen, and recording vs sharing can't be told apart.
  - Each shows only after `Config.indicators.delay` (1 s) of continuous use, so screenshots and device probes don't flash it.
  - Space priority: the unread count, the special chip's name and the battery percentage drop in that order when the island would pass `Appearance.island.maxWidth`.
- **E5. Motion polish.** Done: grow/shrink curves picked by the real size change, overshoot room as a fraction of the tallest mode, section cross-fades, a sliding tab underline, fading indicators, `Config.animations.speed`, and `Hyprland` hand-off notes in `docs/HYPRLAND.md`. Shared-element album art was skipped (needs a shared overlay; not cheap).
  - Content cross-fades on every section change.
  - Expand overshoot and collapse curves as ISLAND.md "Motion".
  - Spam-test every IPC toggle.
- **E6. Theming.** On wallpaper change, run `matugen` → `theme.json`. `Colors` reloads on its own. Every role except `island` follows the wallpaper.
  - Done: `Theme` service (IPC `theme`), `Config.theme.fromWallpaper` / `scheme`, `Config.wallpaper.folder`, contrast fixes, and Settings → Appearance with a wallpaper picker, scheme buttons and a live preview before Apply. Dark only; `surface` stays black.
  - Not done: matugen templates for kitty, GTK or Hyprland borders (now ROADMAP F11).

The build plan ends here. Further features (wallpaper selector, launcher providers, clipboard, emoji, polkit, capture, utilities and more) are in `docs/ROADMAP.md`.

## Open decisions and unverified items

The design rests on Quickshell 0.3.2 source and docs read on 2026-11-05. None of the code snippets have been run in a live session yet, so check the items below as each feature is built.

**Decisions for you**

- [ ] Where the shell lives: `~/.config/quickshell/ezshell` for `qs -c`, or `~/.config/ezshell` next to `config.json` for `qs -p`.
- [x] Where `theme.json` lives: `~/.local/state/ezshell/` since E6, because it is generated.
- [ ] Whether to keep `services/Time.qml` or bind `SystemClock` directly in the bar.

**Not yet verified**

- Which Quickshell version Arch's `extra/quickshell` ships. 0.3.2 or later is required for the JsonAdapter and FileView crash fixes and for `Quickshell.Networking`.
- Whether `adapterUpdated` fires for edits inside a `list<var>`, for example editing a special workspace in place. Reassigning the whole list is the safe pattern.
- ~~Whether the exec-with-workspace dispatch opens the workspace~~: on Hyprland 0.56 it places the window silently, so `Hypr.toggleSpecial` opens the workspace first. `services/Hypr.qml` also handles Lua configs, where dispatch takes `hl.dsp.*` expressions.
- ~~Whether Bluetooth PIN or passkey pairing exists~~: it doesn't (0.3.1 has `pair()` but no agent), so only devices that pair without a code work.
- `Quickshell.Bluetooth` can't power an rfkill soft-blocked adapter; `Bt.setEnabled(true)` runs `rfkill unblock bluetooth` first.
- `Quickshell.Networking` 0.3.1 missed a Wi‑Fi connection that was already active when the shell started (seen with two NM profiles for one SSID). `Wifi` falls back to the device's `connected`, with the SSID unknown. Unverified whether it is fixed by a reconnect or a newer Quickshell.
- ~~Whether inotify fires on `/sys/class/backlight` files~~: it does for writes from `brightnessctl`, so `Brightness` watches the sysfs file with a `FileView` and sees changes from any tool. Changes made by firmware alone are untested.
- `NightLight` runs `hyprctl hyprsunset` through a `Process` rather than `execDetached`, so it can warn when hyprsunset isn't running (hyprctl exits with 3).
- Material Symbols axis names (`FILL`, `opsz`) against the installed font file.
- For E2, test on the real machine:
  - whether `HyprlandFocusGrab` alone routes keys to the Wi‑Fi password field when the island was opened by keybind;
  - whether an input method (fcitx/IBus) works inside the island surface.

**Sources**

- [Quickshell guide v0.3.2](https://quickshell.org/docs/v0.3.2/guide/) · [FAQ](https://quickshell.org/docs/v0.3.2/guide/faq) · [Introduction](https://quickshell.org/docs/v0.3.2/guide/introduction) · [IpcHandler](https://quickshell.org/docs/v0.3.2/types/Quickshell.Io/IpcHandler)
- [Quickshell source mirror](https://github.com/quickshell-mirror/quickshell)
- [caelestia shell](https://github.com/caelestia-dots/shell)
- [hyprism](https://github.com/kristyancarvalho/hyprism)
- [end-4 dots-hyprland](https://github.com/end-4/dots-hyprland)
- [hyprsunset](https://github.com/hyprwm/hyprsunset)
