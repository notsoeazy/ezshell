# 08 · Research notes

Findings behind the other docs, gathered 2026-11-12. Paths under "Caelestia" are
relative to `~/.config/quickshell/caelestia` (commit `fd630ffe`).

## Caelestia

### How the drawers work

- `modules/drawers/Drawers.qml`: `Variants` over screens; each gets one
  `ContentWindow` and an `Exclusions` scope.
- `ContentWindow.qml`: **one fullscreen transparent layer window per screen**
  (all four anchors, `ExclusionMode.Ignore`). Bar, panels and backgrounds all
  live in it. The window never resizes.
- `Regions.qml`: the window's input `mask` is a `Region` built by subtracting
  each panel's rectangle from the screen interior, so only drawn areas take
  input. Rectangles track the panels' animated geometry.
- `Exclusions.qml`: reserved space comes from separate 1px windows with an empty
  mask and an `exclusiveZone`, one per edge.
- `HyprlandFocusGrab` on the window gives outside-click dismissal; it is active
  only while a dismissible drawer is open. `WlrLayershell.keyboardFocus` switches
  to `OnDemand` only while the launcher or session menu is open.
- Layer switches from `Top` to `Overlay` when something must show over a
  fullscreen window.
- `Panels.qml`: each drawer is a `Wrapper` item anchored to an edge.

### The show/hide idiom

Every `Wrapper.qml` has the same few lines (see `modules/dashboard/Wrapper.qml`):

```qml
readonly property bool shouldBeActive: screenState.dashboard && Config.dashboard.enabled
property real offsetScale: shouldBeActive ? 0 : 1

visible: offsetScale < 1
anchors.topMargin: (-implicitHeight - 5) * offsetScale
opacity: 1 - offsetScale

Behavior on offsetScale { Anim {} }

Loader { active: root.shouldBeActive || root.visible; sourceComponent: Content {} }
```

One animated number drives position, opacity, visibility and loading. Adopted as
rule F4.

### Where the overshoot comes from

`components/Anim.qml` is a `NumberAnimation` whose default type is
`DefaultSpatial`. The curve is a bezier whose control points exceed 1.0
(`plugin/src/Caelestia/Config/tokens.hpp`):

| Curve | Control points |
| --- | --- |
| expressiveFastSpatial | 0.42, 1.67, 0.21, 0.9 |
| expressiveDefaultSpatial | 0.38, 1.21, 0.22, 1 |
| expressiveSlowSpatial | 0.39, 1.29, 0.35, 0.98 |
| expressiveFastEffects | 0.31, 0.94, 0.34, 1 |
| expressiveDefaultEffects | 0.34, 0.8, 0.34, 1 |
| expressiveSlowEffects | 0.34, 0.88, 0.34, 1 |
| standard | 0.2, 0, 0, 1 |
| emphasizedDecel | 0.05, 0.7, 0.1, 1 |
| emphasizedAccel | 0.3, 0, 0.8, 0.15 |

In QML these become `easing.type: Easing.BezierSpline` with
`easing.bezierCurve: [x1, y1, x2, y2, 1, 1]`.

Current Caelestia adds a second effect on top: its C++ blob renderer deforms the
drawer shape while it moves (`deformAmount` in `ContentWindow.qml`). That part is
not reproducible in pure QML and is not planned. The bezier overshoot alone gives
the bounce.

### Inverse rounding: two generations

- **Current**: `Caelestia.Blobs` (C++ signed-distance-field renderer) merges
  rectangles with smoothing. Out of scope.
- **Previous** (deleted in commit `c126075d`, readable with
  `git show c126075d^:modules/dashboard/Background.qml`): one `Shape` with
  `CurveRenderer`, and one `ShapePath` per drawer made of `PathArc` and
  `PathLine` segments. Concave corners are arcs with the default direction,
  convex ones use `PathArc.Counterclockwise`. A `flatten` flag shrinks the
  vertical radius when the drawer is shorter than two radii. **This is the
  technique to adapt**; the dashboard background is nearly the island's shape
  already (top-attached, centred).

### Other patterns worth keeping

- Per-screen UI state in a `PersistentProperties` object (`components/ScreenState.qml`),
  which survives hot reload.
- Popout wrapper sizes itself from the *target* content's implicit size
  (`nonAnimWidth`/`nonAnimHeight` in `modules/bar/popouts/Wrapper.qml`) and
  animates towards it. Same idea as the island's size contract.
- Services as typed singletons over Quickshell modules (`services/Audio.qml`).
- OSD shows on service change signals with a restartable hide timer that does
  nothing while hovered (`modules/osd/Wrapper.qml`).
- `shell.qml` touches a few singletons in `Component.onCompleted` to force them
  to load at startup.
- Useful instance pragmas: `QS_NO_RELOAD_POPUP=1`, `QS_DROP_EXPENSIVE_FONTS=1`,
  `QSG_RENDER_LOOP=threaded`.
- Vendored fuzzy matchers in `utils/scripts/` (`fzf.js`, `fuzzysort.js`).

### Thumbnails

Caelestia keeps downscaled copies of images on disk, in its C++ plugin
(`plugin/src/Caelestia/Multimedia/imagecache*.cpp`): a worker thread scales the
image, stores it under a SHA-256 of the path, size and fill mode, and evicts old
entries. ezshell does the same job without compiled code: one low-priority
ImageMagick process at startup writes any missing thumbnails into
`~/.cache/ezshell/thumbnails`, named by an MD5 of the path, and reports each
to the `Wallpapers` service. There is no eviction.

### What makes Caelestia complex (and is avoided here)

- 161 C++ files: config system, tokens, blob renderer, models, i18n.
- Per-monitor config through attached properties on every item.
- Many independent drawers whose interactions are handled case by case
  (`Interactions.qml` is 330 lines; `Panels.qml` cross-wires drawers).
- `services/Nmcli.qml` at 1,831 lines and `VPN.qml` at 838.
- A large in-shell settings app (`modules/nexus`).

## Quickshell 0.3.2

From the guide pages (introduction, size-position, qml-language, advanced, FAQ)
and the type index.

- Config is a directory with `shell.qml`; run from anywhere with `qs -p <dir>`,
  or `qs -c <name>` under `~/.config/quickshell/<name>/`.
- `import qs.<path>` is the recommended way to import your own directories;
  `root:/` imports break the language server and singletons.
- Singletons: `pragma Singleton` + root type `Singleton`.
- Sizing: implicit size flows up, actual size flows down; never use
  `childrenRect`; prefer `RowLayout`/`ColumnLayout`; wrapper types exist for the
  single-child case. (Rules D1–D7.)
- One process for the whole shell; `Loader`/`LazyLoader` to save memory.
- Rounded windows: transparent window with a shape inside. If a window switches
  between opaque and transparent colours, set `surfaceFormat.opaque: false`.
- A transparent `Rectangle` with a touched `border` punches a hole (QTBUG-137166);
  set `border.width: 0`.
- `IpcHandler` functions need explicit types; callable with
  `qs ipc call <target> <fn> <args>`.
- qmlls cannot resolve `PanelWindow` and has no docs for Quickshell types.
- The guide warns that most public configs do not reflect current best practice.

Modules relevant to this shell: `Quickshell` (PanelWindow, FloatingWindow,
Variants, LazyLoader, PersistentProperties, Region, SystemClock, DesktopEntries),
`.Hyprland` (GlobalShortcut, HyprlandFocusGrab, workspaces, toplevels),
`.Wayland` (WlrLayershell, IdleInhibitor, ScreencopyView, BackgroundEffect,
WlSessionLock), `.Io` (Process, FileView, JsonAdapter, IpcHandler, Socket),
`.Networking`, `.Bluetooth`, `.Services.Pipewire`, `.Services.Mpris`,
`.Services.Notifications`, `.Services.UPower`, `.Widgets` (wrappers,
ClippingRectangle, IconImage).

Found while building the services:

- Services are created on first use and report defaults for a moment before
  their real values arrive. Anything that treats a change as an event must
  ignore the first second or two (see `Pulses`).
- `Hyprland.activeToplevel` is empty until focus first changes after startup;
  `Hypr` falls back to the toplevel whose Wayland handle is activated.
- With a Lua Hyprland config, dispatchers are Lua expressions
  (`hl.dsp.focus({ workspace = 3 })`); `Hyprland.usingLua` tells which mode.
- `UPowerDevice.percentage` is 0..1.

Not checked in depth yet, verify when reached: the full `Network`/`Networking`
API, `BackgroundEffect` support on Hyprland 0.57, `JsonAdapter` behaviour with
nested objects.

## Apple HIG

Read from the HIG's documentation data (the site is JavaScript-rendered): 
components index, materials, typography, colour, motion, layout, SF Symbols,
live activities, buttons, toggles, sliders, segmented controls, text and search
fields, progress indicators, popovers, notifications.

Points that shaped the design:

- **Live activities / Dynamic Island**: compact, minimal and expanded
  presentations of the same content; opaque black background; content snug
  within a margin concentric to the outer edge; animate layout changes and keep
  as much of the existing layout as possible when changing size.
- **Motion**: purposeful, brief, optional, cancellable; avoid animating
  frequent interactions heavily.
- **Popovers**: one at a time; never one emerging from another; animate size
  changes; close on outside click and keep the user's work.
- **Toggles**: switches belong in list rows; elsewhere use a button that behaves
  like a toggle; state differences must be obvious and not colour-only.
- **Buttons**: distinguish the preferred action by style, not size; one
  prominent button; destructive role uses red.
- **Sliders**: minimum on the leading side; optional icons at each end; live
  feedback while dragging.
- **Progress**: prefer determinate; never switch between spinner and bar.
- **Typography**: macOS default 13 pt, minimum 10 pt; the text style table in
  05-design-system.md.
- **Materials**: Liquid Glass is for the control layer and should be used
  sparingly in custom components; thicker materials for legibility. The shell
  stays opaque in v1.

The HIG gives few pixel measurements for controls. Sizes in 05 are starting
values to tune by eye, not Apple specifications.

## Fonts and icons

Apple's SF fonts and SF Symbols were considered and dropped: their licences
restrict them to Apple platforms, and SF Symbols has no Linux distribution.

Chosen: Geist and Material Symbols Rounded, both vendorable (checked
2026-11-12). Lucide and Phosphor were earlier picks, kept below for the record.

- **Material Symbols Rounded**: Apache-2.0. One variable font,
  `variablefont/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf` in
  `github.com/google/material-design-icons` (about 15 MB), with a `.codepoints`
  file beside it listing every icon name (about 4,300). The repo has no
  releases, so a commit is pinned. Icons are drawn by typing their name (the
  font uses ligatures), and Qt sets the axes with `font.variableAxes`. Caelestia
  uses the same font from the system package `ttf-material-symbols-variable`.
  Two problems found in use: (1) a vendored copy alongside the system package
  (same family name, different versions) made Qt lay text out with one file and
  draw with the other, giving wrong icons, so the system package is used and
  nothing is vendored; (2) Qt's default (distance field) text renderer garbles
  the filled shapes, whose outlines overlap, so icons use
  `Text.NativeRendering`. The installed package (2.874) has about 4,100 icons,
  215 fewer than the current upstream list.

- **Phosphor** (replaced: separate font file per weight, fill could only
  crossfade, needed a generated name table): MIT licence. The npm package `@phosphor-icons/web` (2.1.2)
  ships one TTF per weight under `src/<weight>/`: `Phosphor.ttf` (regular),
  `Phosphor-Bold.ttf`, `Phosphor-Fill.ttf`, `Phosphor-Light.ttf`,
  `Phosphor-Thin.ttf`, `Phosphor-Duotone.ttf`, 450–570 KB each. Font family
  names are `Phosphor`, `Phosphor-Bold`, `Phosphor-Fill`, and so on. Each
  directory has a `style.css` with rules of the form
  `.ph.ph-wifi-high:before { content: "\e4ea"; }` (about 1,530 icons), which is
  the simplest input for generating the name → codepoint map. Codepoints are
  identical across weights (`wifi-high` = `e4ea`, `speaker-high` = `e44a` in
  both regular and fill). Duotone renders each icon as two layered glyphs and
  is not planned. Fetchable without npm from
  `cdn.jsdelivr.net/npm/@phosphor-icons/web@<version>/src/`.

- **Geist**: `github.com/vercel/geist-font`, OFL-1.1, latest release v1.9.2.
  Variable fonts in the repo at `fonts/Geist/variable/Geist[wght].ttf` and
  `fonts/GeistMono/variable/GeistMono[wght].ttf` (about 170 KB each). Not in the
  official Arch repos as plain Geist, which is another reason to vendor it.
- **Lucide** (not chosen: single stroke weight, no filled variants): ISC licence. The npm package `lucide-static` (1.72.0) ships
  `font/lucide.ttf` (about 1 MB) and `font/info.json`, which maps every icon
  name to its codepoint (`"a-arrow-down": { "encodedCode": "\\e585", ... }`).
  Fetchable without
  npm from `cdn.jsdelivr.net/npm/lucide-static@<version>/font/`.
- Caelestia loads its vendored font the same way: a `FontLoader` in `shell.qml`
  pointing at `Quickshell.shellPath("assets/...")`.

## A note on Caelestia's "Drawer"

Caelestia has a `modules/drawers/` directory, but no shared `Drawer` base
component in the version read here: each drawer's `Wrapper.qml` repeats the same
show/hide lines by convention. ezshell turns that convention into a real
component (`Reveal`), so consistency is enforced rather than copied.
