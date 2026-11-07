# ezshell

A personal Quickshell (QML) desktop shell for Hyprland on Arch Linux. Pure QML, Quickshell 0.3.2 or later, no C++ plugin, no companion CLI, no Python daemon.

The full design, with code skeletons, is in `docs/DESIGN.md`. Read the relevant section before adding a feature or a new file.

This file is the project's single source of instructions for any coding agent. Nothing about the project lives outside the repo: decisions are in `docs/DECISIONS.md`, open items and the current state in `docs/MEMORY.md`. Read both before planning, and update them as you go.

## Handing off

- **Where the work is:** the table in `docs/ROADMAP.md` ("Order and status"). The row marked `next` is the next feature; its section holds the decisions already made. `docs/MEMORY.md` lists open items and what is untested.
- **Run:** `qs -c ezshell` (or `qs -p ~/Projects/personal/shell` for the working copy). The user's own shell may already be running; a test instance runs beside it.
- **Test from a terminal first:** `qs -c ezshell ipc show` lists every IPC target and function; `qs -c ezshell ipc call <target> <fn> [args]` calls one.
- **Format and lint** every changed QML file:
  - `/usr/lib/qt6/bin/qmlformat -i <file>`
  - `/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml -I "$(sed -n 's/^buildDir="\(.*\)"/\1/p' .qmlls.ini)" <files>` while `qs` runs (see "Run and test" for warnings to ignore).
  - Check the `qs` log for errors.
- **Every feature ends the same way:** docs updated (`docs/ISLAND.md`, `docs/DESIGN.md` IPC table, `docs/HYPRLAND.md` binds, this file for new services, shell-outs or rules), its row in the ROADMAP table marked `done` with leftovers noted in its section, new decisions in `docs/DECISIONS.md`, then commit and push.

## Current priority

The functional shell and the enhancements (DESIGN.md "Build plan", phases 1–6 and E1–E6) are done. New work follows `docs/ROADMAP.md`:
- Take the next feature in its table unless the user names another.
- Follow its "How to work on a roadmap feature" steps: plan and wait for an OK, service and IPC before UI, then mark the feature done and commit.

Test wallpapers are in `~/Pictures/Wallpapers/`. Wallpapers are drawn by the shell itself; never add swww, awww, hyprpaper or imagemagick.

## Run and test

- Run: `qs -c ezshell`. Use `qs -p <path>` if the shell isn't in `~/.config/quickshell/ezshell`.
- Every feature must work from a terminal before it has UI: `qs -c ezshell ipc call <target> <fn> [args]`.
- List IPC targets: `qs -c ezshell ipc show`.
- Format: `/usr/lib/qt6/bin/qmlformat -i <file>`. `/usr/bin/qmlformat` is the Qt 5 one and mangles pragmas. Keep `.qmlformat.ini` to `IndentWidth=4`: in qmlformat 6.11, `SemicolonRule=essential` and `MaxColumnWidth` de-indent function bodies and break template strings. Wrap lines over 120 columns by hand.
- Lint: `/usr/lib/qt6/bin/qmllint`, with the import paths and `buildDir` from `.qmlls.ini` (only resolves while `qs` runs). Ignore the "pragma Singleton without qmldir", `FileViewAdapter` incomplete type, `PanelWindow is not creatable`, `QProcess::ExitStatus ... onExited`, `margins` grouped-property, and unresolved-type warnings for `Quickshell.Bluetooth` types, `Notification.actions`, `PwNodeType::Flags` and the polkit `AuthFlow`/`Identity` types (Quickshell type-info gaps).

## Testing

Tests never touch the user's real data.
- Use scratch folders (point `Config` paths at them for the test and restore them after), a scratch cliphist database (`CLIPHIST_DB_PATH`), and stand-ins on `PATH` for `wl-copy` and `notify-send`.
- Never clear or delete the user's notifications, clipboard history, screenshots or recordings, and never run `notifs clear`.
- Never cancel a polkit prompt after a password was requested: PAM's faillock counts it as a failed login and locks the account after three.
- Never show on-screen overlays (slurp, pickers) or simulate input without asking.
- If a test can only run against real data, ask first.
- Point `XDG_CONFIG_HOME` and `XDG_STATE_HOME` at scratch copies when a test changes a setting (do not disturb, game mode, night light), so the user's running shell never sees it. Never leave game mode or do not disturb on.
- Don't touch the user's Wi‑Fi profiles or reconnect without asking.
- Stop test shells with `pkill -x -f "qs -p <path>"` or by PID. A loose `pkill -f` pattern can match your own command line or other processes (it once killed polkit-gnome).
- caelestia's shell still runs beside ezshell and owns `org.freedesktop.Notifications`. Test notifications on a private bus (`dbus-run-session`); its portal helpers may crash when that bus ends, which is harmless.
- Use stand-ins for media too: never skip or pause the user's player to trigger a mode; `osd nowPlaying` shows the now-playing pill on demand.

## Working with the user

- Build roadmap features step by step: post a short plan and wait for an OK, then stop after each step so the user can test.
- Commit only when the user asks or a roadmap feature is finished, and push after committing. Never commit `notes.md`: it's the user's private notes (`docs/MEMORY.md` carries any open points from it).
- Never edit the user's Hyprland config (`~/.config/hypr`). Recommend binds in `docs/HYPRLAND.md`, in the user's Lua style: `hl.bind("SUPER + X", hl.dsp.exec_cmd(qs .. "target fn"), { description = "Group: Action" })`, with `qs` the `qs -c ezshell ipc call ` prefix. Check keys against `~/.config/hypr/hyprland/keybinds.lua` and `variables.lua` first.
- Clipboard workflow: Super+V picks an entry, then the user pastes with Ctrl+V. No auto-paste, `wtype` or Alt+Enter.
- Ask before decisions the user should make; record each answer in `docs/DECISIONS.md` with the date and the reason.

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
modules/<feat>/  feature UI; entry file named after the module (island/Island.qml, settings/Settings.qml)
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
8. Shell or Python → `scripts/`, called by exactly one service through `Quickshell.shellPath("scripts/x.sh")`. One-off generators run by hand (`scripts/emoji-gen.py`) also live there; the shell never runs them.

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
- Modules never talk to each other. Share data through a service, and UI state through `Visibility`. One exception: the island hosts the launcher's view (`modules/island/ModeLayers.qml` imports `qs.modules.launcher`).
- Components take data through properties and report through signals.
- Services never know UI exists. The OSD listens to services itself; services don't trigger it.

## Services

- Root is `Singleton`. Expose state as `readonly property` and intent as verb functions (`set`, `toggle`, `up`, `down`).
- Each service has its own `IpcHandler`, whose target is the service name in lowercase. IPC functions are typed (`: void`) and only delegate.
- Native modules first: Pipewire (with `PwObjectTracker`), Mpris, Networking, Bluetooth, UPower, NotificationServer, SystemTray, Hyprland. Shell out only for brightness (`brightnessctl`, `ddcutil`), night light (`hyprctl hyprsunset`), lifting a Bluetooth rfkill block (`rfkill unblock bluetooth`), saved / hidden Wi‑Fi profiles (`nmcli`), session actions (`systemctl suspend|reboot|poweroff`, through `execDetached` in `Session`), and `SysInfo`'s `df`, `nvidia-smi` (only while the GPU is awake) and `scripts/sysinfo-paths.sh`, and `Camera`'s `scripts/camera-watch.sh` (`inotifywait` on `/dev/video*`), `Theme`'s `matugen`, `Wallpapers`' `find` (Qt's folder model doesn't recurse), and `Clipboard`'s `cliphist` and `wl-copy` (never `Quickshell.clipboardText`), and `Capture`'s `grim`, `slurp`, `gpu-screen-recorder`, `hyprctl -j activewindow`, `wl-copy`, and `notify-send` for its notifications (Open and Edit through `execDetached`: `xdg-open`, `swappy`/`satty`), `Color`'s `hyprpicker`, `Keyboard`'s `hyprctl -j devices`, `Keybinds`' `hyprctl -j binds`, and `GameMode`'s `hyprctl -j getoption` and `hyprctl eval` (`--batch keyword` on a classic config). `Weather` uses `XMLHttpRequest`, no process.
- Never reuse a Quickshell singleton name. Use `Audio`, `Players`, `Wifi`, `Bt`, `Hypr`, `Battery`, `Notifs`, `Tray`, `Apps`, `Time`, `Brightness`, `NightLight`, `Idle`, `Session`, `Weather`, `SysInfo`, `Camera`, `Theme`, `Wallpapers`, `Clipboard`, `Emoji`, `Polkit`, `Capture`, `Color`, `Keyboard`, `GameMode`, `Keybinds`.
- A service may own a non-singleton helper file in `services/` to stay short (`WifiProfiles`, created only by `Wifi`). Nothing else instantiates it.
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

- One root type per PascalCase `.qml` file. Aim for 150 lines and split at 250, unless the code is efficient and splitting would only scatter it: then a file may go over 250. Efficient code comes before the line count.
- No new file for something used once and under about 30 lines. No pass-through wrapper components.
- Comment only *why* (workarounds, tool quirks, units, ordering). No banners, no commented-out code, no filename headers.

## Before finishing a change

- [ ] Layering respected, and no module-to-module imports.
- [ ] No literal sizes, colors or durations.
- [ ] No new `Timer` where an event source exists, and no `Process` outside `services/`.
- [ ] Everything typed, and delegates bound.
- [ ] New settings have exactly one key with its default in the adapter.
- [ ] No file over 250 lines unless it's efficient and splitting would only scatter it, and hidden UI is lazy-loaded.
- [ ] `qmlformat` clean, `qmllint` clean, and `qs` starts with no errors in its log.
