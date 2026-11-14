# 01 · Overview

## Vision

One shape at the top centre of the screen, attached to the screen edge. It is
small when nothing is happening and grows, in place, into whatever is needed:
status, a control panel, the launcher, a wallpaper strip, an OSD. Everything the
shell shows comes out of that shape and goes back into it. A separate floating
settings window handles deeper configuration.

The reference points are Apple's Dynamic Island (one shape, many sizes, content
that swaps as it resizes) and Caelestia's drawers (shapes fused to the screen edge
with inverse-rounded corners, overshoot on open).

## Goals

1. **One morphing surface.** Every view is drawn inside the same shape. Changing
   view means animating width and height and swapping content, never opening a
   second, unrelated popup.
2. **Motion is the product.** Transitions are interruptible, never block input,
   and stay smooth. A feature that cannot be animated cleanly is redesigned.
3. **Much simpler than Caelestia.** Pure QML, no C++ plugin, no build step. Lean
   on Quickshell's built-in services instead of wrapping CLI tools.
4. **HIG-flavoured, consistently.** A small component library modelled on Apple's
   Human Interface Guidelines, driven entirely by tokens.
5. **Everything reachable by IPC.** Any view can be opened, and any action run,
   from a keybind or script.

## Non-goals (v1)

- Other compositors. Hyprland only.
- A system tray, taskbar or dock.
- Per-monitor configuration, beyond choosing which monitor hosts the island.
- Wallpaper-derived colour schemes. The palette is fixed light HIG colours plus
  an accent for now; `matugen` dynamic theming is planned later.
- Liquid Glass. The island is opaque.
- Apple's fonts and symbols. Geist and Material Symbols Rounded are used instead.
- Internationalisation.

The project is called **ezshell**.

## Glossary

Use these words in code, commits and docs. They are deliberately distinct.

| Term | Meaning |
| --- | --- |
| **Island** | The morphing shape and the window that hosts it. Lives on one configured monitor. |
| **View** | Anything the island can display. Exactly one view is current at a time. |
| **State** | A view the island moves between *on its own*: `idle`, `default`, `hovered`. |
| **Control panel** | The quick-settings view. Opened deliberately, has pages. |
| **Page** | A screen inside the control panel: the root page, or a detail page (`wifi`, `bluetooth`, ...). This is what the spec called "mini controls". |
| **Sheet** | A view opened on demand that takes over the island: `launcher`, `wallpaper`, `notifications`, `calendar`, `session`. This is the name for the spec's "panels/modules". |
| **OSD** | A transient view shown in response to an event, then dismissed by timer. Has two content kinds: **level** and **toast**. |
| **Pulse** | The short-lived promotion from `idle` to `default` after an event. |
| **Service** | A singleton that owns system state (audio, network, ...). No UI. |
| **Component** | A reusable HIG-style UI primitive. Knows nothing about the shell. |
| **Module** | A feature directory under `modules/` that composes components and services. |
| **Token** | A named design constant (colour, size, duration, curve). |

"Sheet" is borrowed from the HIG, where a sheet is a modal surface that emerges
from its parent's top edge. That is exactly how these behave. "Panel" was avoided
because Quickshell already uses it for `PanelWindow`, and the HIG uses it for
floating utility windows.

## The four kinds of view at a glance

| Kind | Views | Entered by | Left by | Keyboard | Outside click |
| --- | --- | --- | --- | --- | --- |
| State | `idle`, `default`, `hovered` | automatic | automatic | no | n/a |
| Control panel | `controlpanel` + pages | click, IPC | Esc, outside click, toggle | on demand | closes |
| Sheet | `launcher`, `wallpaper`, `notifications`, `calendar`, `session` | IPC, keybind, click | Esc, outside click, toggle | yes if it has text or key navigation | closes |
| OSD | `osd` (level, toast) | service event, IPC | timer | no | ignored |
