# ezshell — Dynamic Island Rules

Read this before touching `modules/island/`. It extends `docs/DESIGN.md`; every rule there (layering, tokens, typing, file size) still applies.

The visual source of truth is the Figma file [ezshell island](https://www.figma.com/design/PfqwaF0rHtaNaMdksefDir), page "Island states" (frames "09 v3 — Default island variations" and onward). When this doc and Figma disagree on a pixel, Figma wins. When they disagree on behaviour, this doc wins.

## Files

```
modules/island/
  Island.qml            Transients + Variants over screens: exclusion window + island window
  Transients.qml        watches services, sets Visibility.temporary, clears it after Config.osd.hideDelay
  Surface.qml           the pill: background, outline, morph, mode switch
  ModeLayer.qml         one mode's content, with the fade-out / delayed fade-in
  Default.qml           resting island: Leading + center + Trailing (balance rule)
  OsdView.qml           volume / brightness mode
  MessageView.qml       message mode: mic mute, capture feedback, "Copied", `osd say`
  NotificationView.qml  notification banner mode (frame 06)
  MusicView.qml         compact music mode on a track change (frame 03)
  Equalizer.qml         3-bar equalizer, used by Leading and MusicView
  Leading.qml           workspace indicator, special chip, music indicator
  Trailing.qml          Indicators + status icons
  Indicators.qml        recording, mic/camera, DND, unread badge (highest priority first)
  Workspaces.qml        dots and active pill
  PeekView.qml          hover peek's second line: focused app, media chip, notification status
  Expanded.qml          expanded island: header (tabs or back chevron) + Loader for Visibility.panel
  ExpandedHeader.qml    tab row, or back chevron + title + main switch
  dashboard/
    ControlTab.qml  MediaTab.qml  SystemTab.qml  WeatherTab.qml  CalendarTab.qml
    QuickToggles.qml    Control's tiles and round buttons
    Tile.qml            pill tile with a round icon, tile rule built in
    ControlSlider.qml   Control's Sound and Display sliders
    MediaRow.qml        Control's media row (only while a player is active)
    NotificationCenter.qml  Control's notification list: dismiss, Clear all, empty state
    cards/              Card (shell), ClockCard, MonthGrid, MediaControls: only cards used by two or more tabs
  sections/
    WifiSection.qml  BluetoothSection.qml  AudioSection.qml  PowerSection.qml  DisplaySection.qml
    WifiPassword.qml    sub-page pushed from WifiSection
    ListRow.qml         list row (frame 08 style), shared by the sections
    SettingsLink.qml    "… settings" link at the end of each section
```

- Island mode lives in `Visibility`:
  - **`panel`** is the expanded section opened on purpose: a tab (`control`, `media`, `system`, `weather`, `calendar`) or a detail section (`wifi`, `bluetooth`, `audio`, `power`, `display`). `overview` and `notifications` are aliases for `control` (`Visibility.canonical`); `notifications` also scrolls Control to the notification center.
  - **`peekScreen`** is the screen whose island is peeking, set by hover or `island peek on|off`.
  - **`stack`** holds sub-pages inside a section, e.g. `["password"]`.
  - **`temporary`** holds short modes: `volume`, `brightness`, `mic`, `notification`, `music`. (`transient` is a reserved word in QML, hence `temporary`.)
  - The launcher uses the same `panel` property. The island ignores names it doesn't know.
  - The settings app is the exception: its own `settingsPage` (E1), so the window stays open while the island changes. `open("settings", page)` takes a page as the second argument, and collapses the island.
- **Priority:** polkit > expanded (`panel` is an island section) > temporary > peek > rest. Rest is `hidden` under a true fullscreen window.
  - While expanded, temporary modes don't take over; the open section already shows live values.
  - Banners that arrive while expanded are skipped. They still land in the notification list.
- The island never stores its own open state.
- New data goes in services: `Weather` (new) and `SysInfo` (new, CPU/RAM/GPU/disk/net/temp), built as DESIGN.md "What every service looks like". Each gets an `IpcHandler` and no UI knowledge. `SysInfo` runs its `Timer` only while the System tab is open, and `Weather` fetches only while the Weather tab is open, each driven by a property the module sets (`SysInfo.active`, `Weather.active`).
- Add every new size as an `Appearance.island.*` token and every new color as a `Colors` role. No literals in island files.

## Shell of the island

| Property | Value | Token |
| --- | --- | --- |
| Fill | pure black `#000` in every theme | `Colors.island` |
| Outline | 1px `outlineVariant` at 40% opacity | `Colors.outlineVariant`, `Appearance.island.outlineOpacity` |
| Position | top-center, 6px from the top edge | `Appearance.island.margin` |
| Resting height | 44 | `Appearance.island.height` |
| Radius | `height / 2` in pill modes | derived |
| Padding (sides) | 14 | `Appearance.island.padding` |
| Item gap | 8 | `Appearance.spacing.normal` |
| Status icon size | 18 | `Appearance.font.size.icon` |
| Clock | `HH:mm`, 15px SemiBold, `onSurface` | `Appearance.font.size.clock` |
| Date | `ddd d MMM` ("Thu 5 Nov"), 13px Medium, `onSurfaceVariant` | `Appearance.font.size.normal` |
| Dashboard | width per tab (control 440 … media 820), radius 28 | `Appearance.island.dashboard.*` |
| Compact music, media expanded, OSD, notification banner, quick settings, launcher | sizes from Figma frames | `Appearance.island.<mode>.*` |

Text uses `Appearance.font.family` (Google Sans Flex). Icons use `MaterialIcon` only.

Color names in this file use Material 3 spelling (`onSurface`, `onPrimaryContainer`). In `Colors.qml` every `onX` role is spelled `xFg`, because QML rejects properties that start with `on` plus a capital letter. Use the matching `xFg` role in code.

## Default island

The resting island (the former "peek" design) has three sections:

- **Leading:** workspace indicator. Active workspace is a 22x8 `primary` pill, others are 8x8 dots, empty ones dimmed. Width animates when the active workspace changes.
- **Center:** clock + date, one group.
- **Trailing:** status icons in order wifi, bluetooth, volume, battery, 8px apart.

## The balance rule

The most important rule in this file. It is a layout rule, so it is not visible in Figma; check it in code review.

1. The center group (clock + date) is always exactly centered on the island and on the screen.
2. Leading and trailing always have **equal width**: `sideWidth = max(leading.implicitWidth, trailing.implicitWidth)`.
3. `islandWidth = 2 * sideWidth + centerWidth + 2 * gap + 2 * padding`.
4. When one side gains items (tray icons after the workspace indicator, an extra indicator on the right), **both** sides grow by the same amount. Leading content hugs the outer-left edge, trailing content hugs the outer-right edge; the slack sits next to the center.
5. Width changes always animate through the morph or `Anim`. They never jump.

```qml
RowLayout {
    id: root

    readonly property real sideWidth: Math.max(leading.implicitWidth, trailing.implicitWidth)

    spacing: Appearance.spacing.normal

    Item {
        Layout.preferredWidth: root.sideWidth
        Layout.fillHeight: true
        Leading { id: leading; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
    }

    Clock {}

    Item {
        Layout.preferredWidth: root.sideWidth
        Layout.fillHeight: true
        Trailing { id: trailing; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
    }
}
```

- Never give the center `Layout.fillWidth`. Its width is its implicit width.
- The surface reads `Default.implicitWidth` as its target width in default mode; the morph animates to it.
- Never center the island by summing children manually. Anchor `Surface` with `horizontalCenter` on the screen-wide window.

## Default island variations

Indicators **add** small icons or dots to a side section; the sides then rebalance. They never remove the workspace indicator or the date.

| # | Variation | Section | Content | Data |
| --- | --- | --- | --- | --- |
| 1 | Music playing | leading, after workspaces | 3-bar equalizer (or `music_note`) tinted with the album-art color; animates only while playing, static `onSurfaceVariant` when paused | `Players.active`, `trackArtUrl` → `ColorQuantizer` |
| 2 | Unread notifications | trailing, before status icons | `primaryContainer` count badge | `Notifs` unread count |
| 3 | Special workspace | leading, **over** the workspace indicator | `tertiaryContainer` chip: config icon + name ("music"); covers the indicator in place with a crossfade/morph, never sits beside it; nothing at all when no special is active | `Hypr.activeSpecial` + `Config.workspaces.special` icon |
| 4 | Recording / screen share | trailing | `error` dot + `screen_share`; no timer, workspaces stay | `Hypr.screenSharing` (Hyprland `screencast` event) |
| 5 | Mic / camera in use | trailing | `warning` 6px dot + `mic` and/or `videocam`; click opens `audio` | `Audio.micInUse`, `Camera.inUse` |
| 6 | Low battery (≤ 15%) | trailing | `battery_alert` in `error` + "12%"; outline turns `error` at 50% opacity | `Battery` |
| 7 | Charging | trailing | `battery_charging_full` in `success` + percentage | `Battery` |
| 8 | Do not disturb | trailing | `do_not_disturb_on` in `onSurfaceVariant`; date stays | `Notifs.dnd` |
| 9 | Keep awake | trailing | `coffee`; a click turns it off | `Idle.inhibited` |
| 10 | Game mode | trailing | `sports_esports` in `primary`; a click turns it off | `GameMode.active` |
| 11 | Keyboard layout | trailing | short code ("US"), only with more than one layout | `Keyboard.code`, `multiple` |

- The equalizer animates bar heights (or a color pulse) with `Anim`. Stop the animation when paused; never leave a running animation on a hidden item.
- Quantize once per track: bind `ColorQuantizer` source to the track art URL, and fall back to `primary` while it has no result. Check the exact property names in the Quickshell docs.
- Derived flags (`lowBattery`, `micInUse`, `recording`) are `readonly property bool` on the service, not expressions in the island.
- `warning` and `success` are new `Colors` roles; add them with fallbacks before use.

**Priority when space is tight**, highest first: recording > mic/camera > low battery > special > music > notifications. Lower ones collapse to icon-only (drop labels and counts) before the higher ones lose anything. The max width is `Appearance.island.maxWidth`.

## Special workspaces

Each entry in `Config.workspaces.special` gets a `kind` field. Default is `"workspace"`.

| Kind | Use | Behaviour |
| --- | --- | --- |
| `app` | one app (music/Spotify) | single floating window, centered, about 70% x 80% of the screen, rounded corners, dimmed scrim behind; never tiled or scrolling |
| `workspace` | general scratch | full-size special workspace with the normal layout (scrolling or dwindle), many windows |

```json
"workspaces": {
  "shown": 5,
  "special": [
    { "name": "music", "icon": "music_note", "exec": "spotify", "kind": "app" },
    { "name": "scratch", "icon": "layers", "exec": "kitty", "kind": "workspace" }
  ]
}
```

- Toggle both kinds with `qs -c ezshell ipc call hypr toggleSpecial <name>`. `Hypr.toggleSpecial` is unchanged.
- Implement `app` with Hyprland window rules on that workspace (float, size, center, rounding, dim around). Rule syntax differs between Hyprland versions and the Lua config, so check the wiki for your version before writing them. Keep them in the user's Hyprland config, not generated by the shell.
- The island shows the chip (variation 3) for both kinds.

## Expanding the island

Clicking the island expands it **in place**: the same surface morphs from the pill into the expanded island. There is no separate popup. Hovering only peeks (below); it never opens a panel. Quick controls (Wi‑Fi, Bluetooth, audio, power) live inside the expanded island; deeper settings live in the settings app.

### Windows never move

The expanded island floats over windows, tiled or floating. The reserved gap at the top of the screen always stays the resting island's height. This uses the two-window setup the island already has:

- **Exclusion window:** 1px wide, holds the exclusive zone at the resting height, empty `mask: Region {}`. Its zone never changes when the island expands. It drops to 0 under a true fullscreen window.
- **Island window:**
  - `ExclusionMode.Ignore`;
  - sized to the largest mode plus `overshootMargin`, and never resized;
  - `mask: Region { item: surface }`, so clicks outside the visible shape reach the windows below.
- **Layers:**
  - Expanded on a normal workspace: `Top`, which is already above normal windows.
  - Expanded over a true fullscreen window: `Overlay`, like temporary modes, and back to `Top` once collapsed (see Motion).

### State and IPC (`state/Visibility.qml`)

```qml
property string panel: ""            // "" = collapsed; or control | media | system | weather | calendar | wifi | bluetooth | audio | power | display | wallpapers | capture | launcher | settings
property list<string> stack: []      // sub-pages inside the section
property string screen: ""           // monitor the panel is open on

function open(name: string, mon: string): void   // expand straight to a section; mon "" = focused monitor
function toggle(name: string): void              // close only if that exact section is open, else switch to it
function back(): void                            // pop sub-page → detail section → control → collapse
function close(): void                           // collapse, clear stack and drafts
```

- `open` sets `panel`, `screen` and an empty `stack` in one step. That is what makes deep links work.
- Only one screen is expanded at a time. The other islands stay at rest.
- `Expanded.qml` maps section names to `Component`s, never a ternary chain. Each section reports its own `implicitHeight`, and the surface morphs to it. Sections never write sizes into state.

| IPC (`panels` target) | Does |
| --- | --- |
| `open(name)` | expand to a section on the focused monitor |
| `toggle(name)` | expand, switch, or collapse if already on it (existing function, now section-aware) |
| `back` | one level back |
| `close` | collapse |
| `island peek on\|off` | show or close the hover peek on the focused monitor (for testing) |

```
bind = SUPER, A, exec, qs -c ezshell ipc call panels toggle control
bind = SUPER, W, exec, qs -c ezshell ipc call panels toggle wifi
```

### Message mode

One temporary mode, `message`, carries every short message: mic mute, capture feedback ("Drag to select", "Starting recording…", "Recording", "Saved · Copied", "Recording saved", failures), "Copied" from clipboard history, and `osd say` / `osd say2` from scripts. Code calls `Visibility.say(message, duration)` with the fields listed in `MessageView.qml`; `Transients` shows it for `duration` ms (0 = until replaced). The pill is as wide as the message, between `island.message.minWidth` and `maxWidth`, with the content centered. A message tagged `source: "capture"` is cleared when the capture ends, without touching other messages.

### Standalone sections

`Visibility.standalone` holds sections opened only by keybind or IPC, never from Control; `back()` and Esc collapse them.

- **`wallpapers`** (`panels toggle wallpapers`, Super+K): a search field over a single row of thumbnails (`components/WallpaperGrid.qml` with `strip: true`). The selection stays centered and the row slides under it; ←/→, the wheel or a touchpad swipe move it, and dragging the row works too. Clicking a side thumbnail centers it; Enter or a click on the centered one applies it and collapses. The wallpaper in use has a check; the footer shows the selected file's path relative to the folder. The search field takes Exclusive keyboard focus, like the launcher.

- **`capture`** (`panels open capture`): Screenshot and Record × Region / Window / Screen as cards, and a sound switch; arrows and Enter. Picking collapses the island and the capture waits for it (`Capture.settle`). Temporary modes around a capture: `capturing` ("Drag to select", "Starting recording…", "Recording") and `captured` (thumbnail, "Saved · Copied"). The recording indicator also follows `Capture.recording`, and a click on it stops the recording.

### What a click opens (deep links)

| Click target on the resting island | Result |
| --- | --- |
| Background, clock or date (rest or peek) | `control` |
| Workspace dots | switch workspace, no expand |
| Special chip | toggle that special workspace, no expand |
| Music indicator | `media` |
| Wi‑Fi icon | `wifi` |
| Bluetooth icon | `bluetooth` |
| Volume icon | `audio`; scrolling on it changes volume without expanding |
| Battery icon | `power` |
| Notification badge | `notifications` (Control, scrolled to the notification center) |
| Peek: app name | `control` |
| Peek: media chip | `media`; its play/pause button only plays or pauses |
| Peek: notification status | `notifications` |

Each icon in `Leading` and `Trailing` has its own `TapHandler` that calls `Visibility.open(name, <this screen>)`. The background handler fires only when no icon took the click. Nested `TapHandler`s that must win over the background use `gesturePolicy: TapHandler.ReleaseWithinBounds`, which grabs on press.

### Hover peek

Hovering the resting island for `peek.openDelay` (150 ms) grows it **taller** into `peek`; leaving it for `peek.closeDelay` (250 ms) returns it to rest. `Config.island.hoverPeek` turns it off. No keyboard focus, layer stays `Top`.

- **Size:** `max(rest width + 2·padding, peek.width 600) × peek.height 88`, radius `peek.radius` 26.
- **Line 1 is the rest layer itself**, anchored to the top and centred, so it is pixel-identical to rest and the clock never moves.
- **Line 2** (`PeekView.qml`): focused app icon + name (or "Desktop") on the left; a media chip (art, title / artist, play/pause) centred, hidden with no player; notification status on the right ("All caught up", "N new" in `primary`, or "Do not disturb").
- Peek starts only from rest. Any panel, temporary mode or polkit prompt closes it at once, and opening a panel clears `peekScreen`.

### Expanded layout and navigation

- **Header on a tab** (`control`, `media`, `system`, `weather`, `calendar`): the tab row, with battery % and a power button on the right.
- **Header on a detail section** (`wifi`, `bluetooth`, `audio`, `power`, `display`): a back chevron, the section title, and the section's main switch on the right (e.g. Wi‑Fi on/off).
- **Esc goes back one level:** password → `wifi` → `control` → collapsed.
- **Width per page** (`Surface.sectionWidth`, tokens in `IslandTokens.dashboard`): control 440, media 820, system 720, weather 560, calendar 440; detail sections and `capture` use `sectionWidth`, `wallpapers` the dashboard width. Every page is capped at `expanded.pageMaxHeight` and scrolls inside it. Clicking outside always collapses.
- Content cross-fades on a section change (out ~80 ms, swap, in) while the size morphs.

### Quick controls vs the settings app

**Tile rule (Control tiles), used everywhere:**
- the **icon** toggles;
- the **body or chevron** opens its detail section;
- right-click on a tile also opens detail.

Tiles without a detail (`hasDetail: false`: Focus, Game mode, Keep awake) toggle from anywhere on the tile. Power is reached from the header's power button, not a tile.

| Section | In the island | Handed to the settings app |
| --- | --- | --- |
| Wi‑Fi | on/off, scan, network list with signal and lock, connect, disconnect, inline password for WPA/WPA2/SAE | saved networks, hidden SSID, 802.1x/enterprise, static IP/DNS, VPN |
| Bluetooth | on/off, discover, device list with battery, connect, disconnect, pairing that needs no code | pairing that needs a PIN or passkey (Quickshell has no agent), trusted/blocked devices |
| Audio | output and input volume, mute, default device | per-app routing, profiles |
| Power | battery %, time left, power profile, lock, suspend, log out, reboot, power off | power and idle timeouts |
| Display | brightness, night light on/off, warmth, schedule (off / sunset / fixed) | theme, scale, fixed schedule times |

- Every detail section ends with a "… settings" link. It opens the settings app on the matching page, then collapses the island.
- Sections call the existing `Wifi`, `Bt`, `Audio` and `Battery` services; no new data paths.
- Wi‑Fi: try `connect()` first, and ask for a password only when it fails for missing secrets.

### Polkit prompt (top priority)

A polkit request outranks everything: `Surface.mode` is `polkit` on the monitor that was focused when it arrived, then the open panel, then temporary modes, then rest. `Visibility` isn't changed, and the panel underneath stays loaded (`ModeLayers.held`), so the island returns to it as it was. While the prompt shows, the island window is on `Overlay` with `Exclusive` keyboard focus, and nothing auto-collapses. The lock screen still covers it.

### Focus and dismissal

- **`keyboardFocus`:**
  - `None` at rest and in temporary modes.
  - `OnDemand` while expanded.
  - `Exclusive` only while the Wi‑Fi password page is shown and the island was opened by keybind/IPC rather than a click.
  - Released on collapse.
- **`HyprlandFocusGrab`** on the island window, active while expanded:
  - `onCleared` (click outside) calls `Visibility.close()`.
  - Ignore a clear caused by the same click that opened the island; use one guard flag, not stacked timers.
  - Check on the real machine whether the grab alone routes keys when the island was opened by keybind.
- **Also collapse on:**
  - workspace or monitor focus change;
  - the monitor going fullscreen;
  - a successful Wi‑Fi connect;
  - opening the settings app.
- **Never auto-collapse** while a text field has focus or a connect or pair is in progress.
- **Password field:**
  - `echoMode: TextInput.Password` with a show toggle;
  - `inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText`;
  - cleared on collapse, failure or section change;
  - never logged, and never passed through IPC or a process command line.

## Dashboard tabs

The dashboard is the `control`, `media`, `system`, `weather` and `calendar` sections of the expanded island. A background click opens `control`. The design record is `docs/ISLAND-R1.md`.

- **Header:** tabs Control | Media | System | Weather | Calendar. Active tab = `primary` text + 3px `primary` indicator. Right side: battery % and a power button.
- **Control** (440 wide, scrolls):
  - tiles in three columns: Wi‑Fi | Focus | Lock, Bluetooth | Night light | Settings, Game mode | Keep awake | Mic mute. Pill tiles (44 high, 30 px round icon, `primary` when on) in two columns, 44 px round buttons in the third;
  - Sound slider (output name; the icon mutes, the chevron opens `audio`) and Display slider (the chevron opens `display`); both drag and scroll;
  - a media row, only while a player is active; it opens `media`;
  - the notification center: count and "Clear all" (second click confirms), a "Do not disturb is on" line, newest first with app icon, "App · 2m", summary and two body lines, ✕ on hover (slides out, then collapses), and a centred "All caught up" when empty.
- **Media:** the full media controls (frame 04).
- **System** (720): two columns of cards: Performance (CPU, RAM with sparklines), Network (rates with sparklines, SSID in the title), Storage (`/`, `/home`), Sensors (CPU, NVMe, Wi‑Fi, GPU or "Sleeping"), System (kernel, uptime, session).
- **Weather** (560): now (icon, temperature, condition, place, feels like, humidity, wind), 12 hourly capsules (now on `primaryContainer`), 7 days with range bars on one shared week scale.
- **Calendar:** clock card above the month grid.
- One file per tab. Load the active tab with a `Loader`; inactive tabs are not instantiated.
- The active tab is `Visibility.panel`, so `panels open system` deep-links to a tab too.
- **Sparklines** (`components/Sparkline.qml`) are a `Canvas`, never a `Shape`: `Shape` paths inside the morphing island froze the shell at ~94% CPU when switching tabs, with either renderer.

| Card element | Value |
| --- | --- |
| Background | `surfaceContainerHigh` |
| Radius / padding / gap | 16 / 16 / 12 |
| Card header | 16px icon + 12px label, `onSurfaceVariant` |
| Values | 13–16, SemiBold |
| Hero clock | 44–48 |

## Motion

- One interruptible `progress` drives `{width, height, y}`; radius is `min(height / 2, cornerRadius)`. It runs through one of two animations, `grow` (OutBack) or `shrink` (standard curve), chosen in `retarget()` from the actual size change: setting `easing.bezierCurve` turns any easing into a Bezier, so one animation can't do both. Compute the new size from the mode there, because the target bindings may still hold the old mode inside `onModeChanged`.
- Each mode has one entry in the mode table (`Surface.sizeFor`; the content of each mode is in `ModeLayers.qml`); changing mode retargets from the current values, never from the previous mode's end state. Detail sections are narrow; tabs and standalone sections (`wallpapers`) are dashboard-wide.
- Every duration goes through `Appearance.anim.scaled(ms)`, which divides by `Config.animations.speed` (bound into `Appearance.anim.speed` in Island.qml; 0 = instant, and the equalizer stops).
- Section changes inside the expanded island fade the page out, swap it, and fade it in (`Expanded.qml`, restartable mid-fade); the tab underline is one item that slides; indicators fade before they leave the layout.
- Expand: slight overshoot (`OutBack`, overshoot ~1.2), 350–450 ms.
- Collapse: no overshoot, 250–300 ms.
- Content fades out in the first ~100 ms and fades in after ~40% of the morph.
- All durations and curves are `Appearance.anim` tokens (add `islandExpand`, `islandCollapse`, `islandOvershoot`). Every `Behavior` uses `Anim {}` or `CAnim {}`.
- The island window is sized to the largest mode plus `Appearance.island.overshootMargin` (`overshootFraction` of the tallest mode, since the bounce scales with the size change), with `mask: Region { item: surface }`, so the morph never resizes a window. A separate 1px window holds the exclusive zone at the resting height.
- **Layers and fullscreen.** The island window sits on `Top`, which is above every normal window, and moves to `Overlay` only over a true fullscreen window while something shows or the morph is still running (`Surface.elevated`). Hyprland hides `Top` surfaces under a true fullscreen window, so games keep direct scanout; any `Overlay` surface blocks it, so the island never stays there.
- Under a true fullscreen window (`Hypr.fullscreen`, which ignores maximized windows), the rest mode is `hidden`: a narrow pill parked above the screen edge. Temporary modes drop in from the top and retract back up.
- Banners last `Config.notifications.timeout` (critical: until dismissed), are skipped under DND (except critical) and over fullscreen unless `Config.notifications.showInFullscreen`. The compact music pill is skipped over fullscreen and while a banner shows.
- Hyprland's own layer animation must be off for the island window, or it fades the pill in after the morph has already run. Not applied yet; see `docs/HYPRLAND.md` §1.

## Checklist before merging island changes

- [ ] Clock + date are centered on the screen in every variation (measure, don't eyeball).
- [ ] Leading and trailing containers have equal width; adding one item on either side grows both.
- [ ] Width changes animate; nothing jumps when an indicator appears or disappears.
- [ ] Workspace indicator and date are never removed by an indicator. The special chip covers the indicator in place.
- [ ] No island state stored outside `Visibility`; no data logic outside services.
- [ ] New sizes and colors added as `Appearance.island.*` / `Colors` tokens.
- [ ] Dashboard tabs are lazy-loaded; `SysInfo` polls only while System is open, `Weather` fetches only while Weather is open.
- [ ] Line 1 of the peek is pixel-identical to rest; peek never starts while anything else shows.
- [ ] Expanding never moves or resizes a window: the exclusion window's zone stays at the resting height, and the island window is never resized.
- [ ] Clicks outside the visible shape reach the windows below.
- [ ] Each status icon opens its own section; `panels open <section>` does the same from a terminal.
- [ ] Esc goes back one level; clicking outside collapses; typing a password never gets interrupted by a collapse.
- [ ] Rapid toggling (`panels toggle control` spam) never leaves the island at a wrong size.
- [ ] Matches the Figma frame for the state you changed.
- [ ] DESIGN.md checklist passes.
