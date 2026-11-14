# ezshell

A desktop shell for [Hyprland](https://hyprland.org), written in pure QML on
[Quickshell](https://quickshell.org). Its centre is **the island**: a small
shape fused to the top of the screen that morphs to show whatever is relevant
(the clock, status, media, notifications, a control panel, the launcher) and
shrinks back when you are done. Around it sit a screen border, a lock screen,
screen capture, wallpaper-driven colours and a settings window.

The design follows Apple's Human Interface Guidelines (type scale, spacing,
control sizes, motion), with Geist as the typeface and Material Symbols for
icons. [Caelestia](https://github.com/caelestia-dots/shell) is the reference
for patterns, not a dependency.

> **Status: under development.** Every planned feature exists, but almost
> nothing has been refined or tried by hand yet. Expect rough edges, unfinished
> decisions and changes to the config format. The [Todo](#todo) below is the
> list of what is being refined, in order.

## Contents

- [Requirements](#requirements)
- [Running it](#running-it)
- [Features](#features)
- [Todo](#todo)
  - [1. Refine the island UI](#1-refine-the-island-ui)
  - [2. Refine tokens and components](#2-refine-tokens-and-components)
  - [3. Test the features](#3-test-the-features)
  - [4. Revamp the settings](#4-revamp-the-settings)
- [Roadmap](#roadmap)
- [Project layout](#project-layout)
- [Documentation](#documentation)

## Requirements

Developed against Quickshell 0.3.2 on Qt 6.12 and Hyprland 0.57.2 (Lua
config), on Arch Linux.

| Needed for | Packages |
| --- | --- |
| The shell itself | `quickshell`, `ttf-material-symbols-variable` (Geist is vendored) |
| Audio, network, Bluetooth, power | PipeWire + WirePlumber, NetworkManager, BlueZ, UPower |
| Brightness, night light | `brightnessctl`, `ddcutil`, `hyprsunset` |
| Launcher clipboard mode | `cliphist`, `wl-clipboard` (something must feed cliphist: `wl-paste --watch cliphist store`) |
| Screenshots | `grim`, `swappy`, `imagemagick` |
| Recording | `gpu-screen-recorder` |
| Colours from the wallpaper | `matugen` |

## Running it

```sh
qs -p .                      # from this directory
qs -p . ipc show             # list every IPC target and function
qs -p . ipc call launcher toggle
```

Settings live in `~/.config/ezshell/config.json` and are optional: every
option has a default. What the shell remembers (do not disturb, night light,
the wallpaper) is kept apart in `~/.local/state/ezshell/state.json`.

Global shortcuts register as `ezshell:<name>` (33 of them); bind them in your
Hyprland config. The list, with the Caelestia binds they replace, is in
[docs/10-phase-14.md](docs/10-phase-14.md).

Two shells cannot own the notification server or the same shortcuts at once:
stop Caelestia first.

## Features

> **Everything below is built but needs refinement and testing.** "Built"
> means it runs and looks right in screenshots of a scratch instance. Anything
> that needs clicking, typing or real hardware has not been tried by hand. The
> [Todo](#todo) is how that gets done.

**The island**

- Five states: `idle` (clock), `default` (workspaces, clock, status icons),
  `hovered` (clock, date, app, workspaces, status, media, latest notifications), `osd`
  (volume, brightness, microphone, toasts) and `banner` (a new notification).
- Morphing between states and views with spring motion; the shape grows out of
  the screen edge.
- Shrinks to the clock when quiet, or can stay in `default` all the time.
- The distribution's logo at the left of `default` (from `/etc/os-release`, or
  `island.logo`); click it for the launcher.
- Special workspaces: a pill with the workspace's icon and name covers the
  workspace dots while one is showing; toggle over IPC, shortcut or launcher.
- A red dot while recording, and a bell on the idle clock while there are notifications.
- Hides above the screen edge during fullscreen; only the OSD shows over it.

**Views**

- **Control panel**, modelled on macOS Control Center: Wi-Fi, Bluetooth, Keep
  awake, Do not disturb, brightness with night light, volume with microphone,
  screenshot and recording buttons, notification summary. Detail pages for
  Wi-Fi, Bluetooth, Audio and Night light.
- **Launcher** with four modes picked by prefix: applications, `>` actions,
  `:` clipboard history, `.` emoji, symbols and Nerd Font glyphs.
- **Notifications** list and banner, with Do Not Disturb.
- **Wallpaper selector**, previewing live on the real background.
- **Calendar** month view.
- **Session**: lock, log out, restart, shut down, with confirmation.

**Around the island**

- **Screen border**: a frame in the island's colour around every screen, with
  configurable thickness and corner rounding; the island hangs from it.
- **Wallpaper** drawn by the shell, with a crossfade between pictures.
- **Lock screen** using the secure session-lock protocol and PAM. The clock
  travels out of the island and back.
- **Locking when idle**: lock, screens off and suspend after configurable
  times, lock before sleep and on `loginctl lock-session`; each can be turned
  off.
- **Screen capture**: screenshots (open in swappy, copy, or save and copy)
  with a frozen-screen chooser for a window, an area or the whole screen;
  screen recording (screen, screen with sound, area) with its own indicator.
- **Colours from the wallpaper**: a Material You palette made with matugen, with
  four styles and terminal colours, mapped onto the shell's colour roles.
  Optional export to open terminals, Hyprland, GTK and your own templates.
- **Global shortcuts** and an **IPC** surface for everything above.

**Settings window** (a normal floating window) with sections for Network,
Bluetooth, Sound, Display, Notifications, Lock screen, Capture, Appearance,
Island, Wallpaper, Launcher and About.

## Todo

This is the refinement checklist: work through it top to bottom. Nothing in the
shell is final, so each item is "look at it, decide, change it". Add notes
under an item as you go.

### 1. Refine the island UI

One entry per state, per view and per control panel page. For each, check:
layout and spacing, sizes against the tokens, light and dark, a wallpaper with
bright and dark colours, hover/pressed/focus, motion in and out, and what it
looks like with nothing to show or too much to show.

**States**

- [x] `idle`: the resting capsule (clock, recording indicator, border join)
- [x] `default`: workspaces, clock, status icons, special workspace pill
- [x] `hovered`: large clock, window title, media controls, compact notifications
- [x] `osd`, level kind: volume, microphone, brightness
- [x] `osd`, toast kind: message and optional second line
- [x] `banner`: a new notification, with image, actions and the pointer held on it

**Transitions**

- [x] idle ⇄ default ⇄ hovered: size, shoulders and content crossfade
- [x] Any view ⇄ any view: interrupted midway, and with reduce motion on
- [x] Retracting for fullscreen and coming back for the OSD

**Views**

- [x] Launcher: applications mode
- [x] Launcher: actions mode (`>`)
- [x] Launcher: clipboard mode (`:`), text and pictures
- [x] Launcher: symbols mode (`.`): emoji, symbols, Nerd Font glyphs; search speed
- [x] Notifications sheet: items, grouping, empty state, Do Not Disturb header
- [x] Wallpaper selector: strip, preview, selection, thumbnails
- [x] Calendar
- [x] Session sheet: the four tiles and the confirm state

**Control panel**

- [ ] Root page: header, toggle tiles, sliders, capture row, notifications row
- [ ] Wi-Fi page: networks, signal, password field, rescan
- [ ] Bluetooth page: paired and nearby devices, battery, scan
- [ ] Audio page: output and input volume, device lists
- [ ] Night light page: switch and temperature

**Other surfaces**

- [x] Screen border: thickness, rounding, the join with the island, against window rounding
- [ ] Lock screen: clock, date, password field, shake on a wrong password, wallpaper scrim
- [ ] Capture chooser: frozen frame, dimming, selection frame, hint pill
- [ ] Recording indicator and the red Stop button
- [ ] Island on a second monitor and on a scaled monitor

**Logic to decide while looking**

- [ ] What may open during fullscreen (today the island retracts and a view opened
      by keybind is invisible but still holds focus; see the known issues in
      [docs/09](docs/09-open-questions.md))
- [ ] Which events pulse the island by default, and for how long
- [ ] Banner behaviour while a panel or sheet is open (today it is not shown)

### 2. Refine tokens and components

Make the look consistent before touching it any more. Everything should come
from `config/Tokens.qml` and the theme; no literals in feature code.

**Tokens**

- [ ] Type: is the six-step size scale (one step above macOS) right? Is each weight used? Is a line height needed anywhere
- [ ] Spacing: audit for off-grid values and repeated one-offs
- [ ] Radius: `sm`/`md`/`lg`/`xl` against what the views actually use; island and border rounding
- [ ] Control sizes: `ControlSize` usage per control; do slider and button heights line up everywhere
- [ ] Icon sizes paired with text styles
- [ ] State tokens: hover, pressed, disabled, focus ring, tint
- [ ] Motion: spatial vs effects durations, reduce motion, animation scale
- [ ] Island tokens: height, paddings, panel and launcher widths
- [ ] Tokens that are really config (or config that is really a token)

**Colour**

- [ ] Role mapping in `theme/GeneratedScheme.qml`: surface, raised surface, island, labels, fills
- [ ] Contrast of every label level on every surface, light and dark
- [ ] Fixed system colours (red, green, ...) next to wallpaper-driven ones
- [ ] Where `Theme.material` is used directly instead of a role

**Components** (check variants, hover, pressed, focus, disabled, light and dark,
reduce motion)

- [ ] Base: `Pressable`, `Surface`, `Label`, `Icon`, `Anim`, `ColorAnim`, `Reveal`, `Morph`
- [ ] Buttons: `Button`, `IconButton`, `ToggleButton`, `SplitButton`
- [ ] Toggles and tiles: `Switch`, `ToggleTile`, `SegmentedControl`
- [ ] Sliders and values: `Slider`, `LevelSlider`, `Stepper`, `ProgressBar`, `Spinner`
- [ ] Text input: `TextField`, `SearchField`, `ValueArea`
- [ ] Selection: `OptionList`
- [ ] Feedback: `Badge`, `Tooltip`, `Separator`
- [ ] Containers: `Group`, `CenteredRow`, `List`, `ListRow`, `Sidebar`, `PageStack`, `ScrollView`, `ScrollBar`

**Consistency passes**

- [ ] Grep for literal sizes, colours, durations and fonts outside the token files
- [ ] Every control reachable and operable by keyboard, with a visible focus ring
- [ ] Hover, pressed and disabled look the same across controls
- [ ] Copy: titles, subtitles and toasts use one voice

### 3. Test the features

Most of these have only been run through screenshots and logs. Try each by hand
and write down what breaks. Take a TTY with you for the lock screen.

**Capture**

- [ ] Screenshot, whole screen: edit (swappy), copy, save and copy
- [ ] Screenshot, window pick: snapping to the window under the pointer
- [ ] Screenshot, area drag: edges, small areas, cancelling with Esc and right click
- [ ] Screenshots on a second monitor and on a monitor with scale other than 1
- [ ] Recording: screen, screen with sound, area (coordinates on multi-monitor and scaled)
- [ ] Recording: stop from the panel, from the island, over IPC; indicator timing; file written
- [ ] Recording survives the shell exiting

**Locking and power**

- [ ] Lock screen: real password unlocks; wrong password shakes and counts a failure
- [ ] Locking from the session sheet, shortcut and `loginctl lock-session`
- [ ] Lock after idle, screens off after idle, suspend after idle
- [ ] Lock before sleep, and waking up locked
- [ ] Idle settings: each step disabled with 0
- [ ] Keep awake stops idle actions
- [ ] Reloading the shell while locked stays locked

**Everyday controls**

- [ ] Night light: switch, temperature, from the panel, shortcut and settings
- [ ] Brightness and volume keys, including the OSD while holding a key
- [ ] Microphone mute, and the microphone indicator
- [ ] Do Not Disturb: banners stop, critical ones still show
- [ ] Notifications: actions, images, dismiss, clear, many at once
- [ ] Media controls with more than one player
- [ ] Wi-Fi: connect with a password, forget, rescan
- [ ] Bluetooth: pair, connect, disconnect, forget, discoverable
- [ ] Audio: switch output and input, per-application volume
- [ ] Wallpaper selector: preview, set, cancel; thumbnails made on first run
- [ ] Launcher: ranking, all four modes, keyboard navigation, clipboard with pictures
- [ ] Special workspaces: toggle over IPC, shortcut, launcher and by clicking the pill
- [ ] All 33 global shortcuts bound in Hyprland and pressed once

**Colours and theming**

- [ ] Wallpaper colours: change the wallpaper and watch every surface follow
- [ ] All four styles on a dark, a bright and a grey wallpaper
- [ ] Dark mode and accent with wallpaper colours off
- [ ] Export to open terminals (needs the switch on), Hyprland, GTK, user templates
- [ ] Turning wallpaper colours off puts the fixed palette back

**System behaviour**

- [ ] Fullscreen: island retracts, OSD shows, border hidden; open a view while fullscreen
- [ ] Hot reload, restart, and a missing or broken `config.json`
- [ ] Config round trip: every setting written and read back
- [ ] Island monitor unplugged and plugged back
- [ ] Border thickness 0, island idle view off, island disabled
- [ ] Windows keep the right distance from the island and the border
- [ ] Nothing left running after the shell exits

### 4. Revamp the settings

Last, once the shell itself has settled: settings expose what is decided, so
decide first. This is also where options get added and removed.

**Decisions to make first**

- [ ] Which options belong in settings, which stay config-file only, and which are
      state (not preferences)
- [ ] Defaults for every option; which are safe on first run (colouring other
      programs is off by default today)
- [ ] Whether anything left in the config is really a token, and the reverse

**Structure**

- [ ] Sidebar order and grouping (Network ... About)
- [ ] One review per section, against the design system: Network, Bluetooth, Sound,
      Display, Notifications, Lock screen, Capture, Appearance, Island, Wallpaper,
      Launcher, About
- [ ] Row wording: titles, subtitles and notes
- [ ] Controls chosen the same way everywhere (switch vs segmented vs stepper)
- [ ] Dependent options greyed out when their switch is off
- [ ] Settings search

**New options to consider**

- [ ] Screen border: show or hide per monitor
- [ ] Per-event control over pulses, banners and toasts in the window (the OSD
      messages are already switchable in the config, under `osd.show`)
- [ ] Shortcut list and how to bind them, shown in the window
- [ ] Capture: past recordings, default area behaviour
- [ ] Theming: which programs, with a preview of what will be written

**Housekeeping**

- [ ] Writing the file keeps unknown keys and comments (today it rewrites everything)
- [ ] Reset to defaults, per section
- [ ] Docs match the final set of options

## Roadmap

Ideas past the refinement work, roughly in the order they matter.

**Colours and theming**

- [ ] Rethink the matugen integration. It works, but it is a separate process with
      JSON in the middle, and its terminal colours had to be computed in QML.
      Options: keep it and tidy it, or generate the Material palette in the
      shell
- [ ] More built-in templates for other programs: Qt/KDE, btop, Discord, kitty,
      foot, Neovim, spicetify (they work as user templates today)
- [ ] Cursor and icon theme following the palette
- [ ] Light/dark switching from the wallpaper, as an option

**Audio**

- [ ] A full audio control to replace `pavucontrol`: per-application volume and
      mute, moving an application to another output, input and output device
      pickers, profiles, and a visible level meter. Per-application volume
      exists on the Sound page; the rest does not

**Island and shell**

- [ ] Activities: one notion of a long-running thing (recording, media, timers,
      downloads) that adds an element to the state views
- [ ] Launcher: Tab to complete a prefix, a calculator mode, wallpaper and session actions
- [ ] Calendar events
- [ ] Active window details: click the app name in `hovered` to open a view with
      the focused window's title, class, workspace and size
- [ ] Power profiles, battery details and a system monitor page
- [ ] VPN toggle and a tray for apps that still need one
- [ ] Lock screen: media controls and a notification count

**Capture**

- [ ] Pause a recording, and a list of past ones
- [ ] Annotation without leaving the shell

**Project**

- [ ] Multi-monitor support: an island per monitor, a wallpaper per monitor,
      workspaces counted per monitor
- [ ] Packaging and an install script
- [ ] Screenshots and a short clip in this README

## Project layout

```
shell.qml            entry point
config/              Config.qml (user settings), Tokens.qml (design tokens), ShellState.qml
theme/               light and dark schemes, the wallpaper's Material palette
components/          reusable UI: controls, containers, base pieces
services/            logic with no UI: audio, network, capture, idle, IPC, ...
modules/
  island/            the island, its views and components
  background/        wallpaper, screen border, exclusive zones
  settings/          the settings window
  lock/              the lock screen
  capture/           the screenshot and recording chooser
utils/               small helpers
assets/              fonts, PAM service, matugen config and templates
docs/                the specification
scripts/             lint and asset generators (run `scripts/lint.sh` after starting the shell once)
```

Imports flow one way: `modules → components → theme → config`, with `services`
beside them. Components never import services or modules.

## Documentation

The full spec is in [`docs/`](docs/README.md): vision, the island's state
machine, every view, the design system, architecture, code conventions and the
decisions taken. [`docs/09-open-questions.md`](docs/09-open-questions.md) lists
known issues to read before changing anything in the same area, and
[`docs/10-phase-14.md`](docs/10-phase-14.md) covers shortcuts, locking when
idle, capture and the colour pipeline.
