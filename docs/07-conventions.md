# 07 · Conventions

**Status: proposal.** These are Caelestia's conventions (its `.editorconfig`,
`.qmllint.ini`, its convention linter `scripts/qml-lint-conventions.py`, and the
patterns in its code) with tweaks for a smaller, pure-QML project. Differences
from Caelestia are listed at the end.

Rules are numbered so reviews can cite them.

## A. Files and naming

- **A1** One component per file, `PascalCase.qml`. Directories are lowercase.
- **A2** Singleton files are named for what they own (`Audio.qml`), not
  `AudioService.qml`.
- **A7** Do not name a type after a Qt Quick type (`Palette`, `Text`, `Item`,
  ...); the built-in wins silently and the error is confusing.
- **A8** When a service has the same name as a Quickshell type or singleton
  (`Bluetooth`, `Network`), import the Quickshell module under a name where
  both are needed: `import Quickshell.Bluetooth as Bt`.
- **A3** ids are `camelCase`; the file's root object is always `id: root`.
- **A4** American spelling to match the QML API (`color`, not `colour`).
- **A5** Soft limit of 250 lines per file. Past that, extract a sibling
  component or an inline `component`.
- **A6** 4-space indent, LF, UTF-8, final newline, no trailing whitespace
  (`.editorconfig`). JSON uses 2 spaces. Format with `qmlformat`.

## B. File structure

- **B1** Order at the top of a file: `pragma` lines, blank line, imports.
- **B2** `pragma ComponentBehavior: Bound` in every file that has a delegate, a
  `Loader`/`Component` body, or an inline component.
- **B3** Import order, one group after another:
  1. `QtQuick`, `QtQuick.*`
  2. other `Qt*`
  3. `Quickshell`, `Quickshell.*`
  4. `qs.config`, then `qs.theme`
  5. `qs.components`, `qs.components.*`
  6. `qs.services`
  7. `qs.utils`
  8. `qs.modules.*`
- **B4** Always import our code by module path (`import qs.services`). No
  relative directory imports, no `root:/` imports; both break the language
  server. This includes singletons in the *same* directory: a file in `config/` reaching `Tokens`
  uses `import qs.config`, otherwise the linter does not see it as
  a singleton. The one exception is importing a `.js` file, which can only be
  done by relative path.
- **B5** Order inside every object, with a blank line between sections:
  1. `id`
  2. property declarations (`required` first, then `readonly`, then the rest)
  3. signal declarations
  4. functions
  5. property bindings and signal handlers
  6. child objects
  7. inline `component` definitions
- **B6** No blank line directly after `{` or before `}`.

## C. Types and properties

- **C9** A group of related properties is a named type: an inline component (the
  sections in `Config.qml`, the groups in `Tokens.qml`) or its own file with a
  typed root, not an anonymous inline `QtObject { ... }` or
  `JsonObject { ... }`. Anonymous groups work at runtime but their members are
  invisible to the linter and language server.
- **C10** Do not declare a property that already exists on the base type
  (`Text.style`, a `content` alias on a base page). Check the base type first.
- **C1** Every property has an explicit type. `var` only for genuinely dynamic
  data such as parsed JSON, with a comment saying what it holds.
- **C2** Every function declares parameter and return types:
  `function setVolume(v: real): void`.
- **C3** Inputs a component cannot work without are `required property`.
- **C4** Anything not meant to be set from outside is `readonly property`.
  Expose inner objects with `readonly property alias`.
- **C5** Reference other objects by id. Use `parent` only for `anchors`.
- **C6** Declare bindings; do not assign. An assignment in a handler destroys the
  binding on that property. If a property must be both bound and imperatively
  changed, split it into an input property and a derived one.
- **C7** No `Component.onCompleted` for things a binding can express.
- **C8** React to singletons with `Connections { target: X; function onY(): void {} }`,
  not `.connect()`.

## D. Layout and sizing

From the Quickshell "Item Size and Position" guide.

- **D1** A component sizes itself with `implicitWidth`/`implicitHeight`, derived
  from its children's *implicit* sizes plus token padding.
- **D2** Do not set `width`/`height`/`x`/`y` on an item managed by a layout,
  wrapper or anchors.
- **D3** Never size from `childrenRect`; it reads actual geometry and creates
  binding loops.
- **D4** Use `RowLayout`/`ColumnLayout` (pixel-aligned), not `Row`/`Column`.
  Always set `spacing` explicitly from a token; the default is 5, not 0.
- **D8** `Layout.fillWidth` on a nested layout does not make it stretch: a
  layout never grows past the maximum width of its own children. To push
  things apart, put an empty `Item { Layout.fillWidth: true }` between them,
  or set `fillWidth` on the leaf items.
- **D5** For a container around one child, use Quickshell's `WrapperItem`,
  `WrapperRectangle`, `WrapperMouseArea` or `MarginWrapperManager`.
- **D6** A view never reads the island's animated size (see 02).
- **D7** A binding-loop warning in the log is a bug, not noise. Fix it before
  moving on.

## E. Design tokens

- **E1** No literal font sizes, font families, radii, spacings, durations or
  easing curves outside `config/Tokens.qml`, and no literal colours
  outside `theme/`. Literal `0`, `1` and
  small structural numbers (a 1px hairline) are fine.
- **E2** Text goes through `Label` with a font size and weight; icons through `Icon` with a
  semantic name. Never a raw `Text` with a font set, never a glyph literal. The
  one picture that is not an icon is the distribution's logo (`Logo`), an image
  looked up by icon theme name or file path (`island.logo`).
- **E5** Icon state is expressed through `Icon`'s properties (`filled`,
  `weight`, `name`), never by stacking or swapping `Icon` items by hand; the
  component animates the change. Graded icons (Wi-Fi, volume, battery) get their
  name from the `Symbols.level()` helper. Icon names are Material Symbols names
  (`snake_case`).
- **E6** Tokens over defaults. A control's size is passed as a size token
  (`size: Tokens.size.lg`), never as the component's own enum
  (`Button.Large`) or a number, and an icon or inset override is an icon or
  spacing token. That way a size means the same thing on every control, and
  changing a token changes everything that uses it.
- **E3** A missing token is added to its token group (or a missing colour to
  `ColorScheme` and both schemes), not worked around locally.
- **E4** Nested radii use the concentric helper.

## F. Animation

- **F1** Animate only with `Anim` (numbers) and `ColorAnim` (colours), which take
  a token type. Never write a raw `NumberAnimation` with a duration.
- **F2** Spatial tokens for position and size; effects tokens for opacity and
  colour. Never an overshoot curve on opacity or colour.
- **F3** Prefer `Behavior on <prop> { Anim {} }` over imperative animations, so
  changes retarget mid-flight.
- **F4** Show/hide goes through `Reveal`, which implements the Caelestia idiom
  once: a `shouldBeActive` bool, one animated progress value derived from it,
  `visible`/`opacity`/offset derived from the progress, and a `Loader` active
  while `shouldBeActive || visible` so content survives its exit animation and
  is then unloaded. Do not re-implement it per feature.
- **F7** Do not bind a Loader's own position, size or `active` to values that
  depend on what it loads. A Loader resizes itself whenever it moves, which
  turns such bindings into binding loops. Put it inside a plain Item and bind
  that (see `Morph`).
- **F8** Anything centred whose width animates must not be centred with a
  pixel-snapping anchor. `anchors.horizontalCenter` rounds the position to
  whole pixels, so the centre shifts by half a pixel on alternate frames and
  the two edges step unevenly. Set `anchors.alignWhenCentered: false` (or
  compute `x`), and give it a whole, even target width so it still lands on
  the pixel grid at rest. `Morph` does the second part itself.
- **F9** Never start an animation in the same frame that creates heavy
  content. Create it first (asynchronously), then animate. `Morph` and
  `Reveal` are the places this is handled; do not work around them.
- **F10** Do not nest two size animations. A `Morph` inside a view sets
  `animateSize: false`, so it reports its new size at once and the island's
  Morph does the animating. Two would chase each other.
- **F5** Animations never gate input and never use `alwaysRunToEnd` on the
  island shape.
- **F6** Everything must look acceptable with `reduceMotion` on.

## G. Components

- **G1** Components import no service and no module. Data comes in through
  properties, intent goes out through signals.
- **G2** Every interactive component builds on `Pressable` and shows hover,
  pressed, disabled and focus states.
- **G3** Variants are enum or string properties on one component
  (`Button { style: Button.Filled }`), not separate component files.
- **G8** A control never changes its own state. It shows the value it is given
  (`checked`, `value`, `current`) and emits intent (`toggled()`,
  `moved(value)`, `selected(index)`); the owner applies it. Two exceptions own
  their state because they must: a text field owns its text, and a list owns
  which row is current. This keeps the
  owner's binding intact (C6) and makes every control usable with a service
  property directly.
- **G4** Build only components in the inventory (05). A component outside it
  needs a consumer first.
- **G5** A new component gets a short header comment saying which HIG component
  it models and anything it deliberately does differently.
- **G6** A component is not done until it has been looked at where it is used,
  in both palettes and with reduce motion on. (The gallery window that used to
  show every component was removed on 2026-11-14.)
- **G7** Shared behaviour goes in a base component (`Pressable`, `Reveal`,
  `Morph`, `View`), never copied between features. If two features animate the
  same way by duplicating code, extract it.

## H. Services

- **H1** `pragma Singleton`, root type `Singleton`, no visual items.
- **H2** State out as `readonly` typed properties, changes in through typed
  functions.
- **H3** Use a Quickshell module before a `Process`. When shelling out, `command`
  is an argument array, never a string passed to `sh -c` with interpolated input.
- **H4** Streaming commands use `SplitParser`; one-shot commands use
  `StdioCollector`. No polling with a `Timer` when an event source exists.
- **H5** External tools are optional at runtime: a missing binary disables the
  feature and logs once, it does not break the shell.
- **H6** Services do not open views. Only `Osd` maps events to UI.

## I. Island and views

- **I1** A view extends `View`, declares its flags, and registers in
  `Registry.qml`. Nothing else is needed to add a view.
- **I2** The current view changes only through `IslandState` functions. Views do
  not set each other's state.
- **I3** Control panel pages and launcher modes are added through their registry
  lists; adding one must not touch the island or the host view.
- **I4** A view must render correctly at every size between its own and its
  neighbours' during a morph: content is anchored or centred, clipped by the
  host, never positioned by absolute coordinates.
- **I5** Heavy content (lists, images) loads asynchronously and never delays the
  morph starting.

## J. Performance

- **J1** Lazy by default: `Loader` for items, `LazyLoader` for windows.
- **J2** Long or unbounded lists use `ListView` with delegates, not `Repeater`.
- **J3** `layer.enabled` and shader effects only where needed, and switched off
  when the item is idle.
- **J4** Images set `sourceSize` and `asynchronous: true`.
- **J5** One Quickshell process. Never a process per widget.

## K. Tooling and workflow

- **K1** `.qmlls.ini` is an empty file next to `shell.qml`, gitignored;
  Quickshell fills it in for the language server.
- **K2** `scripts/lint.sh` must be clean before committing. It runs the Qt 6
  `qmllint` and `qmlformat` from `/usr/lib/qt6/bin`; the ones on `PATH` may be
  Qt 5 builds, which fail silently on Qt 6 syntax. "Not declared as singleton in
  qmldir" infos are expected. Suppress a warning only on
  the line, with a re-enable after it, and only for known Quickshell type gaps
  (`PanelWindow` is one).
- **K3** Run with `qs -p .` from the repo; watch the log for warnings.
- **K4** Conventional commits with a scope: `feat(island): ...`,
  `fix(launcher): ...`, `refactor(services): ...`, `docs: ...`.
- **K5** Behaviour changes update the matching doc in the same commit. The docs
  are the spec.
- **K6** Comments explain why, not what. No commented-out code.

## Differences from Caelestia

| Caelestia | Here | Why |
| --- | --- | --- |
| C++ plugin for config, tokens, blobs, models | Pure QML | Simplicity; no build step |
| Tokens and config as attached, per-screen C++ objects | Plain singletons | No per-monitor config in scope |
| `StyledRect`, `StyledText`, `MaterialIcon` | `Surface`, `Label`, `Icon` | HIG vocabulary; same icon font (Material Symbols Rounded), with animated fill and name checking |
| Show/hide idiom repeated in each drawer's `Wrapper.qml` | One `Reveal` component | Everything reacts the same way by construction |
| Material 3 colour roles from wallpaper | HIG semantic colours, light first, + accent | Design direction; `matugen` later |
| British spelling (`Colours`) | American (`color`) | Match the QML API |
| Many independent drawers on all four edges, every screen | One island on one monitor, one current view | The product idea |
| Drawer visibility as separate bools per drawer | One derived `current` view | Removes conflicting-state bugs |
| `nmcli` wrapper service | `Quickshell.Networking` | Available since Quickshell 0.3 |
| `daemons/` directory | `services/Ipc.qml` plus services | Fewer top-level concepts |
| Custom Python convention linter | Rules B1–B6 by review, `qmllint` + `qmlformat` | Can port the script later if drift appears |
