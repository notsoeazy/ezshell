# 06 · Architecture

**Status: proposal.** Modelled on Caelestia's layout, cut down. Caelestia is
about 280 QML files plus 160 C++ files; the aim here is the same separation of
concerns in a fraction of the size, with no compiled code.

## Constraints

- Pure QML and JavaScript. No C++ plugin, no build step: `qs -p .` runs it.
- Must not depend on Caelestia's plugin (`Caelestia.*` imports), even though it
  is installed on the development machine.
- Quickshell 0.3.2 or later, Qt 6.12, Hyprland.
- The icon font is a system package: `ttf-material-symbols-variable`.
- Optional tools, each for one feature that is skipped or slower without it:
  `imagemagick` (wallpaper thumbnails), `cliphist` and `wl-clipboard`
  (clipboard history), `brightnessctl`, `hyprsunset` (night light).

## Directory layout

```
shell.qml               entry point: pragmas, eager singletons, top-level modules
config/                 settings and design tokens
  Config.qml            user settings, persisted as JSON; each section
                        (appearance, island, idle, ...) is an inline
                        component in this file
  Tokens.qml            design tokens (05-design-system.md); each group
                        (FontTokens, MotionTokens, ...) and the value types
                        they are made of (AnimStyle, ControlSize)
                        are inline components in this file. Other files
                        name a value type as `Tokens.ControlSize`
  ShellState.qml        what the shell remembers between runs (do not disturb,
                        night light); a separate file from the settings
theme/                  colours only
  Theme.qml             the light and dark schemes, the active one, the accent
  ColorScheme.qml       one appearance's colours (light, dark, later matugen)
components/             HIG primitives; know nothing about the shell
  Anim.qml  ColorAnim.qml  Label.qml  Icon.qml  Surface.qml  Pressable.qml
  Reveal.qml            shared show/hide behaviour
  Morph.qml             size-to-content container with crossfade (island core)
  controls/             Button, Switch, Slider, LevelSlider, ToggleTile, ...
  containers/           ScrollView, ScrollBar, List, ListRow, PageStack,
                        Sidebar, Group, CenteredRow
  effects/              shadow, fade edges
services/               singletons owning system state; no UI
  Time  Hypr  Audio  Battery  Network  Media  Bluetooth  Brightness
  NightLight  KeepAwake
  Notifications.qml     the notification server, the list (kept in a state
                        file), the groups, the banner; NotifData.qml is one
                        notification
  Apps.qml  Clipboard.qml    installed apps and launching; clipboard history
  Wallpapers.qml  Session.qml    pictures on disk and the one set; lock,
                        log out, restart, shut down
  Lock.qml              whether the session is locked; the password check
  Idle.qml              locks, turns screens off and suspends when idle;
                        locks before sleep and on request
  Capture.qml           screenshots and recordings
  Theming.qml           the palette from the wallpaper, and colouring other
                        programs from it
  Ipc.qml  Shortcuts.qml    the outside doors: commands and global shortcuts
  Osd.qml               what the OSD is showing, and which service changes
                        raise it
  Ipc.qml               IPC targets (and later global shortcuts)
modules/
  island/
    Island.qml          picks the monitor, creates the window and the reserve
    IslandWindow.qml    the layer window: mask, focus grab, shape, Morph host
    IslandShape.qml     the ShapePath with concave shoulders
    IslandState.qml     singleton: inputs + view resolution
    View.qml            base type every view extends (flags from 02)
    views/
      Registry.qml      singleton: view name -> component
      IdleView.qml  DefaultView.qml  HoveredView.qml
      launcher/         LauncherView, LauncherMode (base), AppsMode,
                        ActionsMode, ClipboardMode, SymbolsMode, Actions.qml,
                        Modes.qml (registry)
      OsdView.qml       level bar or message
      BannerView.qml  NotificationsView.qml
      WallpaperView.qml  CalendarView.qml  SessionView.qml
      controlpanel/     ControlPanelView, PanelPage (base), RootPage,
                        WifiPage, BluetoothPage, AudioPage, NightLightPage,
                        Pages.qml (registry: page name -> component)
      ...               later: controlpanel/ pages, launcher/ modes, wallpaper,
                        notifications, calendar, session, osd
    Pulses.qml          which service events make the island show `default`
    components/         Clock, Logo, Workspaces, StatusIcons, ActiveWindow,
                        MediaControls, NotificationItem, RecordingIndicator
  background/           what sits behind the windows, on every screen:
                        Background.qml (the wallpaper), Border.qml (the frame
                        around the screen), ExclusiveZone.qml (a strip along
                        one edge that windows keep out of; also used by the
                        island for its strip)
  capture/              CapturePicker.qml (a window per screen while choosing),
                        PickerArea.qml (the frozen picture and the selection)
  lock/                 LockScreen.qml (the WlSessionLock), LockSurface.qml
                        (one per monitor), LockContent.qml (wallpaper, clock,
                        password field)
  settings/             Settings.qml (the window), SettingsState.qml
                        (singleton: open, section), SettingsPage, Field,
                        LevelRow, ValueRow, pages/ (one per section)
utils/                  stateless helpers: Symbols (icon names and graded
                        sets), Fuzzy (search ranking)
scripts/                fetch-fonts.sh (pinned downloads), lint.sh
assets/
  fonts/Geist/          Geist, Geist Mono + licence
  pam.d/ezshell         PAM service the lock screen checks the password with
  matugen.toml          the empty matugen config the palette is made with
  templates/gtk.css     filled in for GTK programs
  symbols.tsv           emoji, symbols and Nerd Font glyphs with names
                        (written by fetch-symbols.py)
  fonts/README.md       versions and sources
  ...                   emoji data, default wallpaper
docs/
```

## Layers and dependency direction

```
modules  ──▶  components  ──▶  theme (Theme)  ──▶  config (Config, Tokens)
   │                                                    ▲
   └──────▶  services  ─────────────────────────────────┘
                 │
                 └──▶ utils   (everything may use utils)
```

| Layer | May import | Must not |
| --- | --- | --- |
| `config` | `utils` | anything else |
| `theme` | `config`, `utils` | anything else |
| `utils` | nothing of ours | hold state |
| `components` | `config` (for `Tokens`), `theme`, `utils`, other components | import `services` or `modules` |
| `services` | `config`, `utils`, other services (and `Theming` hands its palette to `theme`) | import `components` or `modules`; contain visual items. Two exceptions: `Ipc` and `Shortcuts` call into modules, since they are the outside doors to them |
| `modules` | everything | import another module's internals |

Consequences:

- A component can be dropped into a blank Quickshell config and work.
- A service can be tested from `qs ipc` with no UI loaded.
- Views talk to services directly (they are singletons); they never talk to each
  other. Cross-view effects go through `IslandState` or a service.
- The one sanctioned cross-module reach is `modules/island` hosting its views.

## Island internals

How the pieces in `modules/island/` relate:

```
Island (resolves Config.island.monitor -> screen)
├─ ExclusiveZone (top)     own window (modules/background); zone = island height
│                          + the configured gap; knows nothing about the shape
└─ IslandWindow            layer window, input mask = shape rect, focus grab
   └─ IslandShape          draws the fill; sized from the Morph's animated size
      └─ Morph             content: Registry.component(IslandState.current)

IslandState (singleton)    inputs: requested view, pointer, pulse
                           output: current view name
Registry (singleton)       view name -> component
```

- The OSD is split in two. `services/Osd.qml` holds what is showing and
  decides which changes raise it; it knows nothing about the island. The island
  shows `OsdView` whenever `Osd.active`, and tells the service when to hold
  back (`blocked`, while a panel or sheet is open) and when it is being pointed
  at (`held`).
- There is one island, so `IslandState` and `Registry` are singletons. Views
  call `IslandState.open()` / `close()` directly, and IPC does the same.
- **Base components carry the behaviour.** `View` (flags, focus, dismissal),
  `Reveal` (show/hide) and `Morph` (resize + crossfade) are written once. A
  sheet, a page or an OSD kind supplies content and flags and inherits the rest,
  so every one of them opens, closes and resizes identically. This is the same
  intent as a shared `Drawer` base, expressed as three small pieces.
- `IslandState.current` is derived from inputs by one function (table in 02).
- The host is a plain `Morph`: it takes the current view's size and animates
  to it. `IslandShape` and the input mask read the Morph's animated size.
  Nothing reads it back into a view's layout.
- `Registry.qml` is the single list mapping a view name to its component;
  `IslandState.open()` rejects names that are not in it.
- The shape is a `QtQuick.Shapes` path with `CurveRenderer`: line along the top
  edge, concave arc down, side, convex arc, bottom, convex arc, side, concave
  arc back to the edge. This is the technique Caelestia used before it moved to
  its C++ blob renderer (see 08-research.md).

## Services

Prefer Quickshell's built-in modules. Only shell out when there is none.

| Service | Backed by | Provides |
| --- | --- | --- |
| `Time` | `SystemClock` (minute precision unless seconds are shown) | Formatted time and date |
| `Hypr` | `Quickshell.Hyprland` | Workspaces, active window, monitors, fullscreen state, dispatch |
| `Audio` | `Quickshell.Services.Pipewire` | Sink/source volume and mute, device lists, streams |
| `Brightness` | `brightnessctl` process (`ddcutil` for external displays, later) | Per-monitor brightness |
| `Network` | `Quickshell.Networking` | Wi-Fi state, scan, connect with PSK |
| `Bluetooth` | `Quickshell.Bluetooth` | Adapter state, devices, connect |
| `Battery` | `Quickshell.Services.UPower` | Level, charging, power profile |
| `Media` | `Quickshell.Services.Mpris` | Active player, metadata, controls |
| `Notifications` | `Quickshell.Services.Notifications` | Server, list, DND, persistence |
| `NightLight` | `hyprsunset` process / IPC | Toggle, temperature |
| `IdleInhibit` | `IdleInhibitor` (`Quickshell.Wayland`) | Keep awake |
| `Apps` | `DesktopEntries` | Application list, launch |
| `Clipboard` | `cliphist`, `wl-copy` processes | History, copy |
| `Wallpapers` | directory scan | List, current, preview |
| `Osd` | — | Queue of level and toast entries; decides which events raise one |
| `Session` | `systemctl`, `loginctl`, the `Lock` service | Lock, logout, reboot, power off |
| `Lock` | PAM (`assets/pam.d/ezshell`) | Whether the session is locked; checks the password. No unlock function and no IPC to unlock |
| `Idle` | `IdleMonitor`, `dbus-monitor` on the login manager, `systemd-inhibit` | Nothing to read; acts on `Session`, `Lock` and `Hypr` |
| `Capture` | `grim`, `magick`, `wl-copy`, `gpu-screen-recorder` | `picking`, `recording`, `elapsed`; `screenshot`, `record`, `stop` |
| `Theming` | `matugen` | Writes the palette file `Theme` reads; colours other programs |

`Quickshell.Networking` is the notable win: Caelestia's `nmcli` wrapper is 1,800
lines; the built-in module exposes Wi-Fi scanning and `connectWithPsk()`
directly.

Service shape (all services follow it):

- `pragma Singleton`, root type `Singleton`.
- Public state is `readonly property` with explicit types.
- Changes happen through typed functions (`setVolume(v: real): void`).
- No service decides what the UI does, with one exception: `Osd` exists to turn
  service events into OSD entries.
- Services load lazily on first reference. Those that must run from startup
  (`Notifications`, `Osd`, `Media`) are touched in `shell.qml`.

## Config, tokens and state

Three singletons, three different lifetimes.

| Singleton | Content | Changed by | Persisted |
| --- | --- | --- | --- |
| `Tokens` | Sizes, fonts, motion; scaled by `Config` | code | no |
| `Theme` (in `theme/`) | Colours; active scheme and accent chosen by `Config` | code | no |
| `Config` | User preferences | settings window, hand-editing the file | `$XDG_CONFIG_HOME/ezshell/config.json` |
| `ShellState` | What the shell remembers: do not disturb, night light; later the wallpaper | the shell | `$XDG_STATE_HOME/ezshell/state.json` |

`Config` and `ShellState` use `FileView` + `JsonAdapter` so the file is watched and
missing keys fall back to defaults declared in QML. Every option has a default;
the shell must start with no config file. Notes from building it:

- Each section is an inline component in `Config.qml` whose root is
  `JsonObject` (`component Appearance: JsonObject { ... }`). Declaring options
  on an anonymous inline `JsonObject` works at runtime but leaves them untyped
  for the linter.
- The file loads asynchronously by default, so the first frame would use
  defaults and then jump. `Config` calls `waitForJob()` once at startup to load
  synchronously.
- The file is written only when an option is changed from QML, and the whole
  file is rewritten from the adapter: keys the shell does not know are lost.

`Tokens` exposes the active palette (light by default, dark defined alongside)
as an object, so a subtree can be handed a different palette than the rest of
the shell (05, Colour).

UI state (`IslandState`) is not persisted across restarts, but should survive
hot reload (`PersistentProperties`).

## IPC and shortcuts

Everything user-triggerable is exposed twice: an `IpcHandler` function in
`services/Ipc.qml` and, where it makes sense as a key, a Hyprland
`GlobalShortcut` in `services/Shortcuts.qml` (the list is in
[10-phase-14.md](10-phase-14.md)). Both call the same `IslandState` or service
function.

| Target | Functions |
| --- | --- |
| `island` | `open(view)`, `close()`, `toggle(view)`, `current(): string` |
| `controlpanel` | `toggle()`, `page(name)` with `wifi`, `bluetooth`, `audio`, `nightlight` |
| `launcher` | `toggle()`, `open(query)` |
| `osd` | `toast(icon, message)`, `level(icon, value)` (built) |
| `audio` | `volumeUp()`, `volumeDown()`, `toggleMute()`, `toggleMicMute()`, `mediaToggle()`, `mediaNext()`, `mediaPrevious()` |
| `capture` | `screenshot(action)`, `screen(action)` with `edit`, `copy`, `save` or empty; `record(mode)` with `screen`, `sound`, `region` or empty; `stop()`, `cancel()`, `recording()` |
| `special` | `toggle(name)`, `active()`, `list()` |
| `brightness` | `up()`, `down()` |
| `wallpaper` | `selector()`, `set(path)`, `next()`, `current()` |
| `calendar` | `toggle()` |
| `settings` | `toggle()`, `open(section)` |
| `session` | `toggle()`; and `lock()`, `logout()`, `reboot()`, `poweroff()`, which act at once with no confirmation |
| `notifications` | `toggle()`, `clear()`, `toggleDoNotDisturb()`, `count()`; for testing: `test()`, `send(title, body, urgency)`, `flood(count)`, `openNewest()` |
| `status` | `workspace()`, `window()`, `audio()`, `battery()`, `network()`, `media()`: read-only, for checking services from a terminal |

```sh
qs -c ezshell ipc call launcher toggle
qs -c ezshell ipc call osd toast photo_camera "Screenshot copied"   # icon = Material Symbols name
qs -c ezshell ipc call osd test                                     # a sample message, no arguments
qs -c ezshell ipc call notifications test                           # a sample notification (needs the shell to own the notification server)
qs -c ezshell ipc call notifications send "Title" "Body" critical   # urgency: low, normal or critical
```

Global shortcuts register under the appid `ezshell`.

IPC functions must declare argument and return types or Quickshell will not
register them; arguments are limited to `string`, `int`, `bool`, `real`, `color`.

## Runtime notes

- **Lazy loading**: `Loader` for items, `LazyLoader` for windows. The settings
  window and every sheet exist only while in use.
- **Reload**: `settings.watchFiles: true` for hot reload during development.
  Adding an inline component (a new section in `Config.qml`, a new group in
  `Tokens.qml`) is not picked up by it: the log says `<Name> is not a type` and
  the shell keeps running the old code. Restart the shell after such a change;
  a fresh start loads it fine.
- **Input method**: `shell.qml` sets `QT_IM_MODULE=compose`. With Qt's default
  Wayland text-input integration, every keyboard-focus change on the island
  (a mouse click that opens the control panel, a switch between views) logs
  `QWaylandTextInputv3::disableSurface ... Trying to disable X but 0x0 is
  focused`, because no text field has the focus at that moment. Compose input
  reads the keyboard directly, so typing, dead keys and compose sequences work
  but input-method editors (fcitx, ibus) do not. Found with real clicks only:
  the warning does not appear for views opened over IPC.
- **Coexisting with Caelestia during development**: two shells cannot both own
  the notification server or the same global shortcuts. Stop Caelestia, or
  develop in a nested Hyprland session.
- **Blur**: Quickshell 0.3 has `BackgroundEffect.blurRegion`
  (ext-background-effect-v1). Support on Hyprland 0.57 is unverified; a Hyprland
  layer rule on the `ezshell-island` namespace is the fallback. The island is
  opaque, so this only matters for future translucent surfaces.
