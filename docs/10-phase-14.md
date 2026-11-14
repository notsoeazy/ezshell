# 10 · Phase 14: shortcuts, special workspaces, capture, theming

Decided on 2026-11-13 and built the same day. This is the spec for the five
parts; the pages they touch (02 to 06) say the same in their own places.

## Decisions

| # | Question | Decision |
| --- | --- | --- |
| 1 | Order | Shortcuts and idle, special workspaces, screenshots, recording, theming |
| 2 | After a screenshot | Three actions: **edit** (open in `swappy`; the default), **copy**, **save** (save and copy). Each has its own shortcut and IPC argument |
| 3 | Capture controls | A row on the control panel: a Screenshot button (the default action) and a Record button in two parts, whose chevron opens the three recording modes |
| 4 | How far theming goes | A full Material palette from the wallpaper, under Material's role names as Caelestia uses them, plus sixteen terminal colours. The shell's own colour roles are taken from it |
| 5 | Light or dark | Stays the user's choice; the wallpaper does not pick it |
| 6 | Other programs | Yes: terminals, Hyprland, GTK, and the user's own templates |
| 7 | Locking by itself | On idle, before sleep and on request; every time is configurable and each can be turned off |
| — | Special workspaces | While one is showing, a pill with its icon and name covers the workspace dots. Toggled over IPC and by shortcut |
| — | Island mixer | Dropped: the Sound section of settings has per-application volume |

## 14a · Shortcuts and locking by itself

`services/Shortcuts.qml` registers a Hyprland global shortcut for everything
worth a key. Bind one in the Hyprland config as
`hl.dsp.global("ezshell:<name>")` (Lua) or `global, ezshell:<name>`.

| Name | Does | Replaces (Caelestia) |
| --- | --- | --- |
| `launcher` | Open or close the launcher | `caelestia:launcher` |
| `controlpanel` | Open or close the control panel | `caelestia:sidebar` |
| `notifications`, `clearNotifications`, `doNotDisturb` | The notification list; dismiss all; Do Not Disturb | `caelestia:clearNotifs` |
| `session` | The session view | `caelestia:session` |
| `lock` | Lock the screen | `caelestia:lock` |
| `settings`, `wallpaper`, `calendar`, `close` | Open or close each; close whatever is open | `caelestia:showall` has no equivalent |
| `screenshot` | Choose a window or an area; the config's action | `caelestia:screenshotFreeze` |
| `screenshotEdit`, `screenshotCopy`, `screenshotSave` | The same, with the action named | |
| `screenshotScreen` | The whole focused screen | `caelestia screenshot` |
| `record` | Start or stop recording, in the config's mode | `caelestia record` |
| `recordScreen`, `recordSound`, `recordRegion` | Start or stop, with the mode named | `caelestia record -s` is `recordSound` |
| `special` | Show or hide the special workspace last shown | `fn.toggle("specialws")` |
| `volumeUp`, `volumeDown`, `mute`, `micMute` | Sound | |
| `brightnessUp`, `brightnessDown` | Brightness | `caelestia:brightnessUp`, `brightnessDown` |
| `mediaToggle`, `mediaNext`, `mediaPrevious` | The media player | `caelestia:mediaToggle`, `mediaNext`, `mediaPrev` |
| `nightLight`, `keepAwake`, `wallpaperNext` | Toggles; the next wallpaper | |

`services/Idle.qml` (config section `idle`, settings section Lock Screen):

- Lock after `lockAfter` seconds without input (default 300), turn the screens
  off after `screenOffAfter` (360), suspend after `suspendAfter` (off). 0 turns
  a step off. Keep Awake holds all three back.
- `lockBeforeSleep`: when the login manager announces sleep, lock, and hold
  sleep back for `sleepGrace` ms so the lock screen is up first.
- `lockOnRequest`: lock when the login manager asks
  (`loginctl lock-session`).
- Idle and sleep lock through `Session.lock()`, so `session.lockCommand`
  applies; a request locks with the shell's own lock screen directly.

## 14b · Special workspaces

- `Hypr` knows which special workspaces exist, which is showing
  (`activeSpecial`, from Hyprland's `activespecial` event) and which was last.
- While one is showing, the island stays in `default` and the workspace dots
  are covered by a pill in the accent's container colour with the workspace's
  icon and name. Clicking the pill puts the workspace away.
- Icons come from `island.specialIcons` in the config (name to Material Symbols
  name); a workspace not listed gets `layers`.
- IPC: `special toggle <name>` (an empty name means the last shown),
  `special active`, `special list`. The launcher has "Toggle <name> workspace"
  for each that exists.

## 14c · Screenshots

- `capture screenshot <action>` (or the shortcut, the control panel button, the
  launcher) saves a still of every screen, then opens the chooser over the
  frozen picture: point at a window to take it, drag for an area, Return for
  the whole screen, Escape or right click to cancel.
- `capture screen <action>` takes the whole focused screen with no choosing.
- Actions: `edit` opens the picture in `capture.editor` (`swappy -f`); `copy`
  copies it; `save` writes `screenshot-<date>-<time>.png` into
  `capture.screenshotDirectory` and copies it. Copy and save confirm with a
  toast. An empty action means `capture.screenshotAction` (default `edit`).
- Stills and unsaved pictures live in `$XDG_RUNTIME_DIR/ezshell`.
- Needs `grim` and ImageMagick (`magick`).

## 14d · Recording

- `capture record <mode>` starts, or stops the one running. Modes: `screen`
  (the focused screen), `sound` (with what the computer is playing, and the
  microphone too if `capture.recordMicrophone`), `region` (choose a window or
  area first, in the same chooser, live). An empty mode means
  `capture.recordMode`.
- Runs `gpu-screen-recorder` as a child of the shell; stopping interrupts it
  so it finishes the file. Saved as `recording-<date>-<time>.mp4` in
  `capture.recordingDirectory`; a toast confirms and the path is copied.
- If the shell exits while recording, the recorder is interrupted the same
  way, so the file is still finished. The shell's other long-running helpers
  (the login-manager listener, the sleep inhibitor, night light) are started
  through `setpriv --pdeathsig` so they end with it too.
- While recording: a red dot (no time) in `idle`, `default` and `hovered`. The
  control panel's Record button
  becomes a red Stop with the time.

## 14e · Colours from the wallpaper

- `services/Theming.qml` runs `matugen` on the wallpaper whenever it changes
  and writes the palette (light and dark, every Material role, `term0` to
  `term15`) to `~/.local/state/ezshell/theme/scheme.json`. `Theme` reads that
  file, at startup before anything is drawn.
- `Theme.material` is the palette under Material's names. `Theme.color`, the
  shell's own roles, is taken from it by `theme/GeneratedScheme.qml`, the one
  place that maps one onto the other. The system colours (red, green, ...) stay
  fixed. With `theming.dynamic` off, the fixed HIG-style palette and the chosen
  accent are used as before.
- `theming.variant` picks matugen's scheme type; settings offers four (Calm,
  Muted, Vivid, Playful).
- Terminal colours: greys from the palette, and the six hues pulled up to 15°
  toward the accent.
- Other programs, each behind its own switch, **off by default** except the
  user's templates, because each writes outside the shell:

| Switch | Writes |
| --- | --- |
| `theming.terminal` | `theme/sequences.txt` in the shell's state, and the same escape sequences to every open terminal. Add `cat ~/.local/state/ezshell/theme/sequences.txt` to the shell's startup file for new ones |
| `theming.hyprland` | `~/.config/hypr/scheme/current.lua`: a Lua table of every colour without the `#`, the format Caelestia writes |
| `theming.gtk` | `gtk.css` in `~/.config/gtk-3.0` and `gtk-4.0`, from `assets/templates/gtk.css` |
| `theming.templates` | Each file in `~/.config/ezshell/templates`, filled in, to `~/.local/state/ezshell/theme/<name>` |

Template placeholders: `{{ $primary }}` is `#rrggbb`, `{{ $primary.strip }}` is
`rrggbb`, `{{ $mode }}` is `light` or `dark`. Any Material role or `term0` to
`term15` can be named.

## Not verified by hand

Listed in [09-open-questions.md](09-open-questions.md) under known issues.
