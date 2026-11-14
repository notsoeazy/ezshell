# ezshell docs

A Quickshell desktop shell for Hyprland built around one idea: a small bar at the
top of the screen that behaves like a dynamic island and morphs to show whatever
is relevant.

Status: **all fourteen phases are built** (2026-11-13). What has not been
tried by hand is listed under known issues in
[09-open-questions.md](09-open-questions.md).

| File | What it holds |
| --- | --- |
| [01-overview.md](01-overview.md) | Vision, goals, non-goals, glossary |
| [02-island.md](02-island.md) | The island: views, state machine, morphing, input |
| [03-views.md](03-views.md) | Spec for every view: states, control panel, sheets, OSD |
| [04-settings-and-later.md](04-settings-and-later.md) | Settings window, background, later features |
| [05-design-system.md](05-design-system.md) | HIG-based tokens, type, colour, motion, component inventory |
| [06-architecture.md](06-architecture.md) | Directory layout, layers, services, config, IPC |
| [07-conventions.md](07-conventions.md) | Code rules (Caelestia-derived, with tweaks) |
| [08-research.md](08-research.md) | What was learned from Caelestia, Quickshell and the HIG |
| [09-open-questions.md](09-open-questions.md) | Decisions taken, known issues, and the build order |
| [10-phase-14.md](10-phase-14.md) | Shortcuts, locking when idle, special workspaces, capture, colours from the wallpaper |

Reading order for a new contributor (human or AI): 01, 05, 06, 07, then 02. The
rest is reference.

## Environment this was designed against

Checked on the target machine on 2026-11-12:

- Quickshell 0.3.2 (`quickshell-git`), Qt 6.12, Hyprland 0.57.2 (Lua config)
- PipeWire + WirePlumber, NetworkManager (iwd backend), BlueZ, UPower,
  power-profiles-daemon
- Present: `brightnessctl`, `ddcutil`, `hyprsunset`, `cliphist`, `wl-clipboard`,
  `gpu-screen-recorder`, `grim`, `slurp`, `swappy`, `hyprpicker`, `matugen`,
  `libqalculate`
- Fonts: Geist is vendored in the repo; Material Symbols Rounded comes from the
  package `ttf-material-symbols-variable`, which must be installed
- No standalone wallpaper daemon is installed; Caelestia currently draws the
  wallpaper itself
