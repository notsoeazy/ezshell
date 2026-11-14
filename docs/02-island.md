# 02 · The island

This is the core of the shell and the riskiest part to build. Everything else is
content placed inside it.

## Anatomy

```
 screen top edge
 ════════════════╮                       ╭════════════════
                 │   inverse (concave)   │
                 │   corners fuse the    │
                 │   shape to the edge   │
                 ╰───────────────────────╯
                    convex bottom corners
```

- One island, on one monitor, horizontally centred, attached to the top edge.
- The top corners curve *outwards* into the screen edge (inverse rounding); the
  bottom corners are ordinary rounded corners. Adapted from Caelestia's drawers.
- Fill is opaque (`Theme.color.island`) and follows the scheme: white in light,
  black in dark. A black island in light mode would need its content to use the
  dark scheme, and colours come from one global theme, so that is not
  supported. No border in v1.
- Content lives inside a clipped area with a margin concentric to the outer shape
  (HIG: "keep content compact and snug within a margin that's concentric to the
  outer edge").

## Window model

One transparent layer-shell window on the island's monitor holds it. The window
never resizes; only the shape inside it does.

| Property | Value | Why |
| --- | --- | --- |
| Anchors | top, left, right, bottom | Sheets such as the wallpaper strip need width; a fixed window avoids animating Wayland surface size, which stutters |
| Exclusion mode | `Ignore` | The big window must not reserve space |
| Input mask | the island's current rectangle | Everything outside the shape is click-through |
| Layer | `Overlay`, always | The OSD must appear over fullscreen apps. Switching layer while running did not take effect, so the island stays on the overlay layer and retracts when a window is fullscreen |
| Keyboard focus | `None`; `OnDemand` while the current view asks for the keyboard | The island must not steal focus while idle |
| Namespace | `ezshell-island` | Lets Hyprland layer rules target it |

**The exclusive zone is a separate entity**
(`modules/background/ExclusiveZone.qml`): a 1px, fully masked window along one
edge whose `exclusiveZone` is a plain number. The island's strip is one of
these on the top edge, sized as the idle height plus `island.reserveGap` from
the config. It does not reference the island's shape or its animated size at
all, so nothing the island does can move application windows. This is
Caelestia's `Exclusions.qml` approach. The strip is always reserved; only the
gap is configurable, and it is added to the island's height and the border's
thickness, so a gap of 0 still keeps the island's own height clear.

**The island hangs from the border.** The screen border (`modules/background/Border.qml`,
`border.thickness` and `border.rounding` in the config) is a frame of the
island's colour on every screen, on the `Top` layer: above every window (a
window dragged over the edge goes under it), below the island's `Overlay`
layer, and under a fullscreen window. Its thickness is kept clear of windows by one 1px window
per edge (`ExclusiveZone.qml`). Exclusive zones on an edge stack, so on the island's
monitor the top gets the border's thickness plus the island's strip. The island
window is positioned from the border's inner top edge, so the border never
covers it or anything it shows (every sheet, the OSD and banners are views of
the island). Thickness 0 turns the border off and the island sits at the top
edge as before. The lock screen covers the border and has none of its own.

Because the reserve is independent, fullscreen needs no special handling for
spacing: a fullscreen window covers the reserved strip, and the border behind
it, as usual. The island pulls itself up above the screen edge, border
included (and gives up its input area) while the
focused workspace has a fullscreen window, and comes back down only for a view
that may show over fullscreen: the OSD.

**Floating over a fullscreen window.** The border is hidden under a fullscreen
window, so there is nothing for the island's concave shoulders to join. While the
OSD shows over one (a fullscreen or a maximized window, whatever the workspace
reports as `hasfullscreen`), the island lets go of the edge and floats as a pill,
`Tokens.island.floatGap` below the screen's edge, with a hairline so that it does
not disappear into a page of its own colour. `IslandShape.shoulder` does it: 1 is
the shoulders, 0 square corners, -1 the pill's rounded corners, and the shape
morphs through them as the window goes in and out of fullscreen. When the island
retracts it also fades out (`effects`, a little quicker than the slide), so the
view that replaces the OSD is not seen sliding away.

Outside-click dismissal uses `HyprlandFocusGrab` on the island window, active only
while a dismissible view is current.

## Views and the size contract

Every view is a component whose root declares `implicitWidth` and
`implicitHeight`. That is the whole sizing contract:

- The island's target size is the current view's implicit size plus padding.
- The island animates its own `width`/`height` towards the target. Views never
  animate their own outer size and never read the island's animated size to lay
  themselves out (that is a binding loop).
- If a view's content changes size while it is current (a notification arrives,
  a page is pushed), the island follows with the same animation.

Each view also declares a small set of flags, read by the island:

| Flag | Meaning |
| --- | --- |
| `wantsKeyboard` | Island requests keyboard focus while this view is current |
| `dismissible` | Esc and outside click close it |
| `holdOnHover` | A timed view stays open while the pointer is over it |
| `showOverFullscreen` | May appear while a fullscreen window is focused |

## Resolving the current view

The current view is a **derived value**, not something code sets directly.
`IslandState` holds a few inputs and one function turns them
into a view name. First match wins:

| Priority | Condition | View |
| --- | --- | --- |
| 1 | a sheet is requested | that sheet |
| 2 | control panel is requested | `controlpanel` |
| 3 | an OSD entry is active | `osd` |
| 3b | a new notification is being announced | `banner` |
| 4 | pointer is over the island (after intent delay) | `hovered` |
| 5 | pulse timer running | `default` |
| 6 | otherwise | `idle`, or `default` when `island.idleView` is off |

Inputs are changed only through `IslandState` functions (`open(name)`, `close()`,
`toggle(name)`, `pulse()`), never by writing properties from a view. This keeps
every transition explainable by reading one function.

Rules that follow from the table:

- Opening a sheet while the control panel is open replaces it; closing the sheet
  returns to states, not to the control panel.
- Only one sheet at a time (HIG: "show one popover at a time").
- No OSD is shown while the control panel is open: its sliders and tiles already
  show the change. Level entries are dropped. Toasts unrelated to anything the
  control panel displays are queued until the island returns to a state, and
  discarded if older than their timeout by then. The same applies under a sheet.
- When a fullscreen window is focused on the screen, the island retracts above
  the edge. Only views with `showOverFullscreen` (the OSD) may drop down.

## State behaviour

```
            event (pulse)              pointer enters
   idle ───────────────────▶ default ─────────────────▶ hovered
    ▲                           │                          │
    └──── pulse timer ends ─────┘◀──── pointer leaves ─────┘
                                       (after grace period)
```

- **Pulse** triggers: workspace change, volume or brightness change, mic mute
  change, new notification, network or Bluetooth connection change, battery
  crossing a threshold or plugging in, media track change. Each trigger restarts
  the timer (default 3 s). The trigger list is configurable.
- **Hover intent**: entering starts an ~80 ms timer before `hovered` shows, so
  passing over the island does not make it jump. Leaving starts a ~300 ms grace
  timer, so small overshoots off the edge do not collapse it.
- Hover is suppressed for a moment after a view closes, so closing the control
  panel under the pointer does not immediately reopen `hovered`.

## Morphing

A transition has two parts that run together.

**Shape.** `width` and `height` animate with a *spatial* curve that overshoots
slightly (Caelestia's `expressiveDefaultSpatial`, bezier `0.38, 1.21, 0.22, 1`).
Because the shape is pinned to the top edge and centred, overshoot reads as a
bounce downward and outward. Width and height may use slightly different
durations so growth does not look like a uniform scale.

**Content.** The outgoing view fades and scales down a little; the incoming view
fades and scales up a little. This uses an *effects* curve with no overshoot.
Outgoing content finishes fading before the shape has shrunk past it, and the
content area is clipped, so nothing ever spills outside the shape.

Requirements:

- **Interruptible.** A new target mid-animation retargets from the current
  values. No queued animations, no `alwaysRunToEnd` on shape animations.
- **Never blocks input.** The incoming view is interactive as soon as it is
  visible.
- **Radius adapts.** When the shape is shorter than twice the corner radius, the
  radii shrink to half the height (Caelestia's `flatten` handling), so the idle
  pill stays a clean capsule.
- **Lazy content.** A view is instantiated when first needed and unloaded after
  it has fully faded out. `idle` and `default` stay loaded.
- **Prepare, then move.** New content is created across frames and drawn
  invisibly for two frames before the switch, so the cost of building it never
  lands in the animation's first frame. Measured cost: about 35 ms before a
  light view starts moving, about 70 ms for a heavy one.
- **Pixel grid.** Target sizes are whole pixels with an even width, and the
  shape is centred without pixel snapping, so the centre stays fixed while the
  width animates and everything is sharp at rest.
- **Reduced motion.** A config switch replaces overshoot curves with standard
  ones and shortens durations (HIG: "make motion optional").

Shared-element transitions (the clock sliding from its `idle` position to its
`hovered` position) are a later refinement. v1 crossfades.

## Input summary

| Input | Effect |
| --- | --- |
| Hover | `hovered` state |
| Click on `idle` / `default` / `hovered` background | open control panel |
| Click on a specific element in `hovered` | open the related sheet (clock → calendar, notifications → notifications sheet) |
| Scroll over volume / brightness element or level OSD | adjust the value |
| Esc | close the current dismissible view, or pop a control panel page |
| Outside click | close the current dismissible view |
| IPC / global shortcut | open, close or toggle any view |

## Multi-monitor

There is one island. `Config.island.monitor` names the monitor that hosts it;
empty means the primary (first) monitor. If the configured monitor is
unplugged, the island falls back to the first available one and returns when it
is reconnected. The reserve window follows the island's monitor.

Views opened by keybind or IPC, and OSDs, therefore always appear on that
monitor, whichever one has focus. A "follow focused monitor" mode is a possible
later option.
