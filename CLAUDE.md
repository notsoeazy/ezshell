# ezshell

A personal Quickshell (QML) desktop shell for Hyprland on Arch Linux. Pure QML, Quickshell 0.3.2 or later, no C++ plugin, no companion CLI, no Python daemon.

The full design, with code skeletons, is in `docs/DESIGN.md`. Read the relevant section before adding a feature or a new file.

## Current priority

Build a functional shell before UI polish. Follow the build plan in `docs/DESIGN.md`:
foundation → plain bar → controls and OSD → connectivity → media and notifications → launcher, wallpaper, lockscreen → settings, theme, dynamic island.

Don't work on the island look or animations until the functional phases are done, unless asked.

## Run and test

- Run: `qs -c ezshell`. Use `qs -p <path>` if the shell isn't in `~/.config/quickshell/ezshell`.
- Every feature must work from a terminal before it has UI: `qs -c ezshell ipc call <target> <fn> [args]`.
- List IPC targets: `qs -c ezshell ipc show`.
- Format: `/usr/lib/qt6/bin/qmlformat -i <file>`. `/usr/bin/qmlformat` is the Qt 5 one and mangles pragmas. Keep `.qmlformat.ini` to `IndentWidth=4`: in qmlformat 6.11, `SemicolonRule=essential` and `MaxColumnWidth` de-indent function bodies and break template strings. Wrap lines over 120 columns by hand.
- Lint: `/usr/lib/qt6/bin/qmllint`, with the import paths and `buildDir` from `.qmlls.ini` (only resolves while `qs` runs). Ignore the "pragma Singleton without qmldir", `FileViewAdapter` incomplete type, `PanelWindow is not creatable`, `QProcess::ExitStatus ... onExited`, `margins` grouped-property, and unresolved-type warnings for `Quickshell.Bluetooth` types, `Notification.actions` and `PwNodeType::Flags` (Quickshell type-info gaps).

## Directory layout

Read `docs/ISLAND.md` before touching `modules/island/`.
Check `docs/FIGMA.md` and the PNG in `docs/design/` before building any UI.

```
shell.qml        ShellRoot only: force-loads startup services, instantiates modules
config/          Config.qml (FileView + JsonAdapter on ~/.config/ezshell/config.json), Paths.qml
themes/          Appearance.qml (static tokens), Colors.qml (reads ~/.local/state/ezshell/theme.json)
state/           Visibility.qml (open panel / island mode, IPC target "panels")
services/        one singleton per system domain
components/      stateless UI primitives (StyledText, StyledRect, MaterialIcon, Anim, CAnim)
modules/<feat>/  feature UI; entry file named after the module (osd/Osd.qml)
utils/           pure-function QML singletons (Icons.qml); qs.<dir> modules don't export .js files
scripts/         non-QML helpers, run only by services
assets/          images, svg, bundled fonts
```

## Where a new thing goes (first match wins)

1. Observes or changes system state → `services/<Domain>.qml` singleton.
2. A user setting → a key in the `Config` adapter. Never a property on a service.
3. A visual constant → `themes/Appearance.qml`. A color → `themes/Colors.qml`.
4. Which UI is open → `state/Visibility.qml`.
5. UI used by two or more modules, or generic → `components/`.
6. UI used by one feature → `modules/<feature>/`.
7. A pure function → a function on a `utils/` singleton.
8. Shell or Python → `scripts/`, called by exactly one service through `Quickshell.shellPath("scripts/x.sh")`.

## Layering (imports point down only)

| Layer | May import | Never imports |
| --- | --- | --- |
| `shell.qml` | modules, config | services (except the startup force-load line) |
| `modules/*` | components, services, state, config, themes, utils | another module |
| `components/` | themes, utils, components | services, modules, state, config |
| `state/` | config, `Quickshell.*` | services, modules, components |
| `services/` | config, utils, other services (acyclic), `Quickshell.*` | modules, components, themes, state |
| `config/`, `themes/` | `Quickshell.*`, utils | everything else |

- Always `import qs.<dir>`. Never use relative imports or hand-written `qmldir` files.
- Modules never talk to each other. Share data through a service, and UI state through `Visibility`.
- Components take data through properties and report through signals.
- Services never know UI exists. The OSD listens to services itself; services don't trigger it.

## Services

- Root is `Singleton`. Expose state as `readonly property` and intent as verb functions (`set`, `toggle`, `up`, `down`).
- Each service has its own `IpcHandler`, whose target is the service name in lowercase. IPC functions are typed (`: void`) and only delegate.
- Native modules first: Pipewire (with `PwObjectTracker`), Mpris, Networking, Bluetooth, UPower, NotificationServer, SystemTray, Hyprland. Shell out only for brightness (`brightnessctl`, `ddcutil`), night light (`hyprctl hyprsunset`), lifting a Bluetooth rfkill block (`rfkill unblock bluetooth`), saved / hidden Wi‑Fi profiles (`nmcli`), session actions (`systemctl suspend|reboot|poweroff`, through `execDetached` in `Session`), and `SysInfo`'s `df`, `nvidia-smi` (only while the GPU is awake) and `scripts/sysinfo-paths.sh`, and `Camera`'s `scripts/camera-watch.sh` (`inotifywait` on `/dev/video*`), and `Theme`'s `matugen`. `Weather` uses `XMLHttpRequest`, no process.
- Never reuse a Quickshell singleton name. Use `Audio`, `Players`, `Wifi`, `Bt`, `Hypr`, `Battery`, `Notifs`, `Tray`, `Apps`, `Time`, `Brightness`, `NightLight`, `Idle`, `Session`, `Weather`, `SysInfo`, `Camera`, `Theme`.
- Processes live only in services, one per data source. Outside services, only `Quickshell.execDetached([...])`.
- Use events, not polling. A `Timer` is a last resort, only in a service, and only running while needed.

## Config

- One file, `~/.config/ezshell/config.json`. Defaults live only in the `JsonAdapter` initialisers.
- Writes happen by assignment (`Config.nightLight.enabled = true`), which triggers a debounced `writeAdapter()`. Only the settings module and IPC handlers write.
- Config holds user choices. Live state belongs in services.
- Hyprland may run a Lua config (`Hyprland.usingLua`), which takes Lua dispatchers (`hl.dsp.focus({ workspace = "3" })`). Dispatch only through `Hypr.dispatch(lua, classic)`.
- Special workspaces are entries in `Config.workspaces.special` (`{ name, icon, exec }`), toggled with `Hypr.toggleSpecial(name)`. Never hardcode workspace names in modules.

## QML style

- Attribute order: id → properties (required, public, readonly, alias) → signals → functions → assignments and handlers → children → states and transitions.
- Bindings over imperative assignment. A binding is one expression; anything longer becomes a typed function or a service `readonly property`.
- Type every property, parameter and return. Use `var` only for raw JSON.
- Use `root` as the root id. Reach outer objects by id. Add `pragma ComponentBehavior: Bound` and `required property var modelData` in delegates.
- No magic numbers: every size, spacing, radius, duration, easing and color comes from `Appearance` or `Colors`. Add a token before you add a literal.
- Never use `transient` as an identifier (reserved in QML). Never declare a property named `on` + capital letter; QML parses it as a signal handler. Material 3 "on" colors are `Colors.<role>Fg` (`surfaceFg`, `primaryFg`).
- Group tokens and config keys in named inline `component` types, not bare `QtObject`/`JsonObject`, so qmllint sees the members.
- Every icon goes through `MaterialIcon` (Material Symbols Rounded ligature names). Every `Behavior` uses `Anim {}` or `CAnim {}`, and any explicit duration goes through `Appearance.anim.scaled(ms)` so `Config.animations.speed` applies.
- Hyprland settings the shell depends on are listed in `docs/HYPRLAND.md`; don't edit the user's Hyprland config.
- Hidden-by-default windows go in a `LazyLoader`. Use `Loader` for Items. Never put `Variants` inside a `LazyLoader`.
- Per-screen windows use `Variants { model: Quickshell.screens }`, with one `PanelWindow` per panel and a `WlrLayershell.namespace` of `ezshell-<name>`.

## Files and comments

- One root type per PascalCase `.qml` file. Aim for 150 lines and split at 250.
- No new file for something used once and under about 30 lines. No pass-through wrapper components.
- Comment only *why* (workarounds, tool quirks, units, ordering). No banners, no commented-out code, no filename headers.

## Before finishing a change

- [ ] Layering respected, and no module-to-module imports.
- [ ] No literal sizes, colors or durations.
- [ ] No new `Timer` where an event source exists, and no `Process` outside `services/`.
- [ ] Everything typed, and delegates bound.
- [ ] New settings have exactly one key with its default in the adapter.
- [ ] No file over 250 lines, and hidden UI is lazy-loaded.
- [ ] `qmlformat` clean, `qmllint` clean, and `qs` starts with no errors in its log.
