# 05 · Design system

The look follows Apple's Human Interface Guidelines (HIG), macOS flavour, dark
appearance first. This file defines the tokens and the component inventory.
Source pages are listed in [08-research.md](08-research.md).

Principle: **components consume tokens, modules consume components.** No size,
font, duration or curve is written as a literal outside `Tokens.qml` in
`config/` (`Tokens.fontSize`, `Tokens.spacing`, `Tokens.motion`, ...), and no colour
outside `theme/` (`Theme.color.label`, `Theme.accent`).

Values marked *(start)* are starting points to verify on screen or against
Apple's design resources; values marked *(HIG)* were read from the HIG.

## Fonts and icons

**Decided: Geist for text, Material Symbols Rounded for icons.** Geist is
vendored under `assets/fonts/Geist/`. The icon font is **not** vendored: it is
the system package `ttf-material-symbols-variable`, a required dependency.
Apple's SF fonts and SF Symbols are not used (their licences restrict them to
Apple platforms). Lucide and then Phosphor were tried first and replaced.

| Role | Font | Licence | Source |
| --- | --- | --- | --- |
| UI text | Geist | OFL-1.1 | vendored, `vercel/geist-font` v1.9.2 |
| Monospace | Geist Mono | OFL-1.1 | vendored, same repo |
| Icons | Material Symbols Rounded | Apache-2.0 | system package `ttf-material-symbols-variable` |
| Nerd Font glyphs | Symbols Nerd Font | MIT | vendored, `ryanoasis/nerd-fonts` v3.4.0; only the launcher's symbol mode draws with it |

- Geist is loaded with `FontLoader` in `shell.qml`; components refer to
  families through `Tokens.font`, never by name.
- **Never ship a copy of a font that is also installed on the system under the
  same family name.** A vendored Material Symbols was tried and failed this
  way: text was laid out with one file and drawn with the other, so the wrong
  icons appeared.
- A wrong icon name is not caught: the font draws its letters. Fix it when you
  see it.

### Why Material Symbols

It is one variable font with four axes, which gives what SF Symbols has and
what the earlier choices only approximated with separate font files:

| Axis | Range | Use |
| --- | --- | --- |
| Fill (`FILL`) | 0 to 1 | Outline to solid; the selected / on state. Animates |
| Weight (`wght`) | 100 to 700 | Stroke weight; match adjacent text |
| Grade (`GRAD`) | -25 to 200 | Fine emphasis without changing size |
| Optical size (`opsz`) | 20 to 48 | Detail tuned to the size shown; set automatically |

- About 4,300 icons, with graded sets for Wi-Fi (0 to 4 bars), volume and
  battery (0 to 6 bars and full).
- **Icons are drawn by name.** The font turns the text `volume_up` into the
  icon, so there is no name-to-glyph table and nothing to generate.

### The `Icon` component

All glyphs go through one component. Code never contains a codepoint or the
font family name.

```qml
Icon { name: "wifi" }
Icon { name: "notifications"; filled: root.hasUnread }
Icon { name: "volume_up"; weight: Font.DemiBold; size: Tokens.icon.lg; level: Icon.Secondary }
```

| Property | Type | Meaning |
| --- | --- | --- |
| `name` | string | Material Symbols name (`volume_up`, `chevron_right`, `dark_mode`) |
| `filled` | bool | The selected / on state. The outline fills in, animated |
| `fill` | real 0..1 | Follows `filled`; set directly for an in-between value |
| `weight` | font weight | `Font.Light` to `Font.Bold`. Default `Font.Normal` |
| `grade` | real | Default 0 |
| `size` | real | An icon size token; optical size follows it |
| `level` | enum `Primary`, `Secondary`, `Tertiary` | Vibrancy level → colour token |
| `color` | color | Override for tinted icons (accent, destructive) |

Behaviour the component owns, so no caller re-implements it:

- **Fill and colour animate** in place. Fill moves in tenths, because every
  distinct axis value is a separate font instance.
- **Native text rendering.** Qt's default text renderer garbles this font's
  filled shapes (their outlines overlap), so `Icon` uses the native one.
- **A change of name crossfades** (with a slight scale) from the old icon to
  the new one, which is what makes `play_arrow` → `pause` and the graded sets
  feel alive.
- **Fixed box.** The item is always `size × size` with the glyph centred, so
  swapping icons never shifts the layout around it.
- **Unknown names** log one warning and show a question mark. Without this the
  font would draw the name as letters.
- **Weight pairing.** Regular text with `Font.Normal`, emphasized text with
  `Font.DemiBold`. Components that pair icon and text set this; callers do not.

Supporting piece: `utils/Symbols.qml`.

- `Symbols.level("wifi", 0.6)` → `network_wifi_2_bar`: picks from a graded set,
  so services expose a number and the icon is chosen in one place.

On/off state is shown twice, as the HIG asks: the container's fill changes and
the icon fills in (or switches to its `_off` variant when disabled).

## Typography

Sizes and weights are separate tokens, named like spacing. The sizes follow the
macOS scale *(HIG)* but each is one step larger than Apple's: Apple's sizes read
too small on this display with Geist. Minimum size is 11. There is no line
height token: text takes the font's own line height, and a caller that needs
another sets `Text.lineHeight` itself.

| `Tokens.fontSize` | Size | Used for |
| --- | --- | --- |
| `xs` | 11 | badges |
| `sm` | 13 | secondary text, group titles, small controls |
| `md` | 15 | body, the default |
| `lg` | 17 | view and page titles |
| `xl` | 20 | sidebar title, large row text, the lock date |
| `xxl` | 26 | the control panel's heading |

| `Tokens.fontWeight` | Value |
| --- | --- |
| `regular` | 400 |
| `medium` | 500 |
| `semibold` | 600 |
| `bold` | 700 |

- Text is set by size and weight, never by raw numbers:
  `Label { fontSize: Tokens.fontSize.md; weight: Tokens.fontWeight.bold }`.
  `emphasized: true` is shorthand for semibold; an explicit `weight` wins.
- A control's text size is part of its `ControlSize` (`size.fontSize`).
- The two clocks have their own sizes, not steps of the scale:
  `Tokens.island.clockSize` (the `hovered` clock) and `Tokens.lock.clockSize`
  (the lock screen's).
- Geist is a variable font. `Label` sets weight on the font's `wght` axis only;
  setting `font.weight` alone snaps medium and semibold to regular, and setting
  both adds synthetic bold on top.
- Clocks and other changing numbers use tabular figures so digits do not shift.

## Colour

Semantic names only. Components never reference a hue directly.

There are two sources for the values behind the token names:

- **The wallpaper** (the default, `theming.dynamic`): `matugen` makes a
  Material palette from it, kept as `Theme.material` under Material's role
  names (`primary`, `onPrimary`, `surfaceContainer`, ...). The shell's roles
  below are taken from it in `theme/GeneratedScheme.qml`, the one place that
  maps one onto the other: `surface` is `surface`, `label` is `onSurface`,
  `labelSecondary` is `onSurfaceVariant`, the accent is `primary`, and so on.
  The system colours stay fixed, so red still means red.
- **The fixed palette**, from Apple's iOS values, with the accent chosen in
  settings. Used when dynamic colours are off or no palette has been made.

Light or dark is always the user's choice. Feature code keeps using the roles
below; reach for `Theme.material` only when no role fits. `Theme.accent`,
`Theme.accentContainer` and `Theme.onAccentContainer` work in both sources.
See [10-phase-14.md](10-phase-14.md) for how the palette is made and what else
it colours.

A palette is an object (type `ColorScheme`; `Theme.light`, `Theme.dark`, and the
active one as `Theme.color`). There is one active scheme for the whole shell;
giving one subtree a different scheme is not supported, because every component
reads the global `Theme`. This is why the island follows the scheme (white in
light, black in dark) instead of always being black.

The values below are the fixed palette, *(start)*, from Apple's iOS palettes.

### Surfaces

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `surface` | `#F2F2F7` | `#1C1C1E` | Window and sheet background |
| `surfaceRaised` | `#FFFFFF` | `#2C2C2E` | Grouped rows, cards |
| `island` | `#FFFFFF` | `#000000` | Island fill |
| `scrim` | black 35% | black 35% | Dim behind modal content |

### Content (vibrancy levels)

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `label` | black 100% | white 100% | Primary text and icons |
| `labelSecondary` | `#3C3C43` 60% | `#EBEBF5` 60% | Secondary text |
| `labelTertiary` | `#3C3C43` 30% | `#EBEBF5` 30% | Placeholders, disabled |
| `labelQuaternary` | `#3C3C43` 18% | `#EBEBF5` 18% | Faint decoration |
| `fill` | `#787880` 20% | `#787880` 36% | Control backgrounds |
| `fillSecondary` | `#787880` 16% | `#787880` 32% | |
| `fillTertiary` | `#767680` 12% | `#767680` 24% | Text field, hover highlight |
| `separator` | `#3C3C43` 29% | `#545458` 60% | Hairlines |

### System colours

| | Light | Dark |
| --- | --- | --- |
| blue | `#007AFF` | `#0A84FF` |
| green | `#34C759` | `#30D158` |
| red | `#FF3B30` | `#FF453A` |
| orange | `#FF9500` | `#FF9F0A` |
| yellow | `#FFCC00` | `#FFD60A` |
| indigo | `#5856D6` | `#5E5CE6` |
| purple | `#AF52DE` | `#BF5AF2` |
| pink | `#FF2D55` | `#FF375F` |
| teal | `#30B0C7` | `#40C8E0` |
| grey | `#8E8E93` | `#8E8E93` |

- `accent` defaults to blue and is user-configurable.
- Roles: `destructive` = red, `success` = green, `warning` = orange.
- Colour is never the only signal (HIG inclusive colour): a toggled tile changes
  fill *and* icon fill; a destructive button is red *and* labelled.
- Every colour change animates through `ColorAnim`, so switching palette
  crossfades the whole UI.

## Shape and spacing

| Token group | Values *(start)* | Notes |
| --- | --- | --- |
| Spacing | 2, 4, 8, 12, 16, 20, 24, 32 | 4 pt base grid |
| Radius | `sm` 6, `md` 10, `lg` 16, `xl` 22, `full` (capsule) | |
| Control heights | mini 18, small 24, regular 28, large 36, extra large 44, tile 60 | One step above macOS control sizes, to suit the larger text |
| Icon sizes | `sm` 20, `md` 24, `lg` 30, `xl` 36 | Material Symbols carry their own padding, so these run larger than the text beside them |
| Min pointer target | 28 × 28 | |
| Island | resting height 40, corner radius 22 (`Tokens.island.radius`), control panel width 408 (the strip kept clear below it is `island.reserveGap` in the config, 4 by default) | |

### Control sizes

Controls do not have size names of their own. They take one of five size
tokens, named like the spacing, font and icon scales (`sm` to `xxl`), each
bundling what should change together:

| Token | Height | Icon | Padding | Text |
| --- | --- | --- | --- | --- |
| `Tokens.size.sm` | 24 | `sm` 20 | 8 | 13 |
| `Tokens.size.md` (the default; also the minimum target) | 28 | `sm` 20 | 12 | 15 |
| `Tokens.size.lg` | 32 | `sm` 20 | 12 | 15 |
| `Tokens.size.xl` | 36 | `sm` 20 | 12 | 15 |
| `Tokens.size.xxl` | 44 | `md` 24 | 16 | 15 |

`Tokens.control` has the same heights (`xs` 18 to `xxl` 44), `row` (48) for a
list row, `tile` (60), and the slider, bar and thumb sizes.

```qml
IconButton { icon: "settings"; size: Tokens.size.lg }
LevelSlider { size: Tokens.size.xxl }   // lines up with the button beside it
```

- `Button`, `IconButton`, `ToggleButton`, `LevelSlider` and `TextField` all
  take `size`. Give two controls the same size and they are the same height.
- Each also has `iconSize` (and `LevelSlider` an `inset`) for the rare case
  where the size's own value is wrong; pass a token, never a number.
- An icon beside text in a button stays at `sm` however tall the button is, so
  it matches the text and not the button.

**Concentricity** *(HIG)*: a rounded element inside a rounded container uses
`innerRadius = outerRadius − padding`. Use `Tokens.concentric(outer, padding)`;
do not eyeball it.

## Motion

Two families, as in Caelestia, because moving things and fading things want
different curves.

| Token | Curve (cubic bezier) | Duration *(start)* | Use |
| --- | --- | --- | --- |
| `spatialFast` | `0.42, 1.67, 0.21, 0.9` | 350 ms | Small elements moving or resizing |
| `spatial` | `0.38, 1.21, 0.22, 1` | 500 ms | Island morph |
| `spatialSlow` | `0.39, 1.29, 0.35, 0.98` | 650 ms | Large sheets |
| `effectsFast` | `0.31, 0.94, 0.34, 1` | 150 ms | Hover, press |
| `effects` | `0.34, 0.8, 0.34, 1` | 200 ms | Opacity, colour |
| `effectsSlow` | `0.34, 0.88, 0.34, 1` | 300 ms | Content crossfade |
| `standard` | `0.2, 0, 0, 1` | 250 ms | Reduced-motion replacement |
| `linear` | `0, 0, 1, 1` | 1000 ms | Continuous loops (spinners) |

Curve control points are Caelestia's defaults, read from its source. Spatial
curves go above 1.0, which is where the overshoot comes from. Durations are
Material 3 Expressive defaults and should be tuned by eye.

Rules *(HIG motion)*:

- Motion has a purpose: it shows where something came from or went. No
  decorative animation.
- Brief and precise. Frequent interactions (hover, press) use the fast effects
  tokens.
- Cancellable. Nothing waits for an animation to finish.
- Optional. `reduceMotion` swaps spatial curves for `standard` and caps their
  durations; an animation speed multiplier scales everything.
- Spatial curves are for position and size only. Never use an overshoot curve on
  opacity or colour.

## Component inventory

HIG components mapped to what the shell needs. All tiers are built. Names drop any prefix:
`Button`, not `StyledButton` (import with a namespace if a Qt Quick Controls
type would clash).

### Tier 0 — foundations everything else is built from

| Piece | Role |
| --- | --- |
| `Anim`, `ColorAnim` | The only animation types; take a motion token |
| `Label` | All text, by size, weight and vibrancy level |
| `Icon` | All glyphs: Material Symbols name, animated `filled`, weight, crossfading swaps (see above) |
| `Surface` | Rounded container with a fill token and animated colour |
| `Pressable` | Shared hover / press / focus / disabled state layer; reports `activated` and, for a right click, `secondaryActivated` |
| `Reveal` | The shared show/hide behaviour. Set `shown`; the child is created lazily, fades, optionally slides (`offsetX`/`offsetY`) or scales (`fromScale`), optionally grows into its layout space (`collapse`), and is destroyed once hidden. Movement follows a spatial curve, opacity an effects curve |
| `Morph` | A container that takes the size of its `content` component and, when that changes, animates to the new size while crossfading. Content keeps its natural size and is clipped, never squeezed. Going back to content that is still fading out reverses in place. With `travel` set, content slides sideways instead of scaling. With `animateSize: false` it leaves the size animation to a Morph around it. The island and the control panel's pages are built on it |

`Reveal` and `Morph` are this project's answer to "everything is a child of one
base component": behaviour lives in one place and features only supply content.

### Tier 1 — the island and control panel

| Component | HIG source | Notes |
| --- | --- | --- |
| `Button` | Buttons | Styles: `Plain`, `Gray`, `Tinted`, `Filled`. Roles: `Normal`, `Destructive`. `size` is one of `Tokens.size`; `capsule` rounds it fully; `neutral` draws a plain button in the secondary label colour (disclosure chevrons). One prominent button per view |
| `IconButton` | Buttons | A `Button` with no text is a square icon button; `IconButton` is the round shorthand. `size` sets its diameter, `iconSize` overrides the icon |
| `ToggleButton` | Toggles | A round icon button that stays lit while something is on: the HIG's toggle for outside a list. Right-click reports a secondary action |
| `ToggleTile` | Controls (Control Center) | Icon, title, status. The whole tile toggles; an optional chevron button opens the detail page. Right-click also asks for the page |
| `SplitButton` | Pull-down buttons | A capsule in two parts: the main part acts, the chevron asks for the choices (`menuActivated`). It does not hold the choices; pair it with an `OptionList` |
| `OptionList` | Menus | A short list of choices with the current one ticked. Takes `options` (`{ title, subtitle, icon }`) and `current`; emits `selected` |
| `Switch` | Toggles | Used in list rows only *(HIG)*; outside a list use `ToggleButton` |
| `Slider` | Sliders | Thin track with thumb |
| `Scrubber` | Progress | A thick bar (`Tokens.control.bar`, growing to `barActive` while held) that fills from the left, no thumb. Draggable when `interactive`: while held it follows the pointer exactly and sends `moved` once, on release (what it moves is slow to answer), then stays where it was let go until `value` arrives; with no progress it is the empty bar. Used for how far through a track you are |
| `LevelSlider` | Controls (Control Center) | Wide capsule track that fills, icon inside, no thumb; also the OSD level bar. Empty means nothing filled: the icon then sits on the bare track in the label colour, and turns to the on-accent colour where the fill reaches it. `size` is one of `Tokens.size`; `iconSize` and `inset` adjust the icon |
| `ValueArea` | — | Shared drag / wheel / arrow-key input behind both sliders |
| `SegmentedControl` | Segmented controls | Equal-width segments with a sliding highlight |
| `Separator` | — | Hairline |
| `ProgressBar`, `Spinner` | Progress indicators | Determinate bar, indeterminate bar, spinner; never morph one into the other *(HIG)* |
| `Badge` | — | Count pill in the accent colour, as tall as a small icon (`Tokens.icon.sm`) with a whole-pixel width |
| `Tooltip` | Offering help | Appears after a hover delay, on top of the whole window |

### Tier 2 — sheets

| Component | HIG source | Notes |
| --- | --- | --- |
| `TextField` | Text fields | Plain and secure (password), optional leading icon and clear button. `size` is one of `Tokens.size`; `capsule` rounds it fully |
| `SearchField` | Search fields | A text field with a magnifier and a clear button |
| `List`, `ListRow` | Lists and tables | Inset grouped style; every row is `Tokens.control.row` (48) tall, with one line of text or two. A leading icon, picture (`image`) or character (`glyph`) sits in a slot of one width so the text lines up, then the title, subtitle and trailing accessories. The current-row highlight and the hover highlight are rounded pills inset by `spacing.xs`, not bands to the edge (`List` takes `inset`, `highlightColor`, `highlightRadius`, `spacing` and `highlightContent`, something drawn inside the current-row highlight so it moves with it; `ListRow` takes `tile` for a rounded tile behind the picture and `hoverInset` and `hoverRadius` to match). `selectable: false` for a plain list |
| `ScrollView`, `ScrollBar` | Scroll views | Overlay scrollbar, usable on any flickable. Edge fades are not built yet |
| `PageStack` | Navigation | `push(component)`, `pop()`, `reset()`; a `Morph` that slides forward on push and back on pop, and handles Escape. Pages are recreated each time they are shown |

### Tier 3 — the settings window

| Component | HIG source | Notes |
| --- | --- | --- |
| `Sidebar` | Sidebars | A column of sections, the current one in the accent colour. Takes `items` (`{ title, icon }`; `gap: true` starts a new cluster) and `current`; emits `selected` |
| `CenteredRow` | none | Keeps its centre item in the middle: `leading` items sit against the left edge and `trailing` ones against the right, and both sides are as wide as the wider one, so the centre never moves and the narrower side's spare room is next to the centre. A side with nothing in it, and its `gap`, take no space. Used by the `idle` and `default` views |
| `SwipeToDismiss` | — | Content that can be dragged sideways away: past `threshold` of its width it slides off and sends `dismissed`, short of that it springs back; it fades as it goes. Used for notifications |
| `KeyHints` | none | One row of hints about a view's keys: `hints` is a list of `{ key or symbol, text }`, shown on the left, with Escape on the far right (`closeLabel`). Used by the launcher and the wallpaper selector |
| `Card` | Boxes | A rounded container with padding (`padding`, `radius`, `color`) around one child, sized to it. The media row sits in one. `interactive` makes the whole card clickable (its click area is under the content, so buttons inside are clicked first); `feedback: false` drops the hover and press highlight |
| `Group` | Boxes | A titled, rounded group of `ListRow`s with an optional note under it |
| `Stepper` | Steppers | A number with minus and plus buttons; `text` says what it means ("3 s"). `size` is one of `Tokens.size` |

Not built, and not needed so far: `Picker`/`PopUpButton`, `Checkbox`,
`DisclosureGroup`, `ColorWell`, `Menu`. Where a picker would go, the settings
use a `SegmentedControl`.

### Every interactive component must

- Show hover, pressed, disabled and keyboard-focus states.
- Be operable from the keyboard when inside a view that takes the keyboard.
- Expose state through properties and intent through signals; it never calls a
  service itself.
- Take its size from its content (`implicitWidth`/`implicitHeight`) and tokens.
