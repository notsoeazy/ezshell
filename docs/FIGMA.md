# Figma design reference

The visual source of truth for ezshell is the Figma file **ezshell — Dynamic Island Shell**:
https://www.figma.com/design/PfqwaF0rHtaNaMdksefDir

Behaviour and layout rules live in `docs/ISLAND.md`. This file says *where* each design is and *what values to copy*. When a value here and a value in Figma disagree, Figma wins; update this file.

## How to read the design

Two sources, in order of preference:

1. **Exported PNGs in `docs/design/`.** Always available, and free to read. Open the image for the frame you are implementing before writing UI.
2. **The Figma MCP server**, if it is connected (`/mcp` shows `figma`). The current Figma plan allows only about 20 MCP tool calls per month, so:
   - Use it only for the frame being implemented, never to browse.
   - Prefer one `get_design_context` or `get_screenshot` call per frame, using the node ID from the table below.
   - If a call fails with a rate-limit error, fall back to the PNGs and this file. Don't retry.

Never copy Figma's generated code as-is. It's a reference: translate it into our components (`MaterialIcon`, `StyledText`, `StyledRect`, `Anim`) and tokens (`Appearance`, `Colors`).

## Frame index

Page **Island states** (node `3:4`). Link a frame with `?node-id=<id with - instead of :>`, e.g. `…/PfqwaF0rHtaNaMdksefDir?node-id=4-15`.

| Frame | Node | PNG in `docs/design/` | Used in phase |
| --- | --- | --- | --- |
| 01 Idle — clock pill | `3:5` | `01-idle.png` | superseded by 02 |
| 02 Peek — **default island** | `3:10` | `02-default.png` | 2 |
| 03 Compact live activity — music | `3:34` | `03-compact-music.png` | 5 (done) |
| 04 Media expanded | `3:49` | `04-media.png` | E3, Media tab |
| 05 Volume OSD | `4:15` | `05-osd.png` | 3 (done) |
| 06 Notification banner | `4:25` | `06-notification.png` | 5 (done) |
| 07 Quick settings | `4:41` | `07-quick-settings.png` | E2: tiles, sliders and power buttons for the Overview toggles and detail sections; not a separate popup |
| 08 Launcher | `4:116` | `08-launcher.png` | **6, current** |
| 09 Default island — variations (v2) | `7:66` | `09-variations-v2.png` | inspiration only (v3 below is current) |
| 09 v3 variations (browser preview) | — | `09-variations-v3.png` | 3–5, **current** |
| 11 Special workspace "music" open | `7:328` | `11-special.png` | 2 |
| 14 Dashboard A — bento (Overview tab) | `8:133` | `14-dashboard-overview.png` | E2 (quick toggles), E3 (full bento) |
| 15 Dashboard B — tabbed | `8:358` | `15-dashboard-tabs.png` | E3 (tab header, System tab) |

There are no frames yet for the expanded `wifi`, `bluetooth`, `audio` and `power` sections (E2). Build them from frame 07's tiles and sliders and frame 08's list rows, using ISLAND.md "Expanding the island". Use a back-chevron header instead of tabs.

Page **Foundations** holds the reusable pieces: `Icon` component (`1:20`, mirrors `MaterialIcon.qml`), `Slider` (`2:10`), `QS Tile` variants (`2:24`).

**`docs/design/09-variations-v3.png`** is the current variations sheet: equalizer or tinted note for music, special chip covering the workspaces, red dot and icon for recording, balanced expansion. It's a browser preview, not a Figma frame, so it has no node ID.
- It shows content and placement only. Exact sizes and colors come from `docs/ISLAND.md` and the color table below.
- The clock and date never wrap. "21:18 Thu 5 Nov" is always one line. When content grows, the island widens, with both sides growing equally per the balance rule.

**`docs/design/09-variations-v2.png`** (Figma frame `09`, node `7:66`) is the previous variations sheet. Keep it as **inspiration only**: ideas like the unread badge, low-battery outline, charging color and DND icon carried over into v3.
- Don't copy the parts v3 replaced:
  - the music row that drops the date for an equalizer icon;
  - the music-note glyph always shown next to the workspaces;
  - the special-workspace chip placed beside the workspaces instead of over them;
  - the recording chip with a timer that replaces the workspaces.
- Frames `10` and `12` show those same replaced designs full-screen, so treat them the same way.
- Where any of these differ from the v3 sheet or `docs/ISLAND.md`, ISLAND.md wins.

## Color roles (Figma variables → `themes/Colors.qml` defaults)

| Role | Hex | Role | Hex |
| --- | --- | --- | --- |
| `island` | `#000000` | `primary` | `#B1C5FF` |
| `surface` | `#121318` | `onPrimary` | `#172E60` |
| `surfaceContainer` | `#1E1F25` | `primaryContainer` | `#2F4578` |
| `surfaceContainerHigh` | `#292A2F` | `onPrimaryContainer` | `#D9E2FF` |
| `surfaceContainerHighest` | `#34343A` | `secondaryContainer` | `#3F4759` |
| `onSurface` | `#E3E2E9` | `onSecondaryContainer` | `#DBE2F9` |
| `onSurfaceVariant` | `#C5C6D0` | `tertiary` | `#E0BBDD` |
| `outline` | `#8F909A` | `tertiaryContainer` | `#5A3D59` |
| `outlineVariant` | `#45464F` | `onTertiaryContainer` | `#FDD7F9` |
| `error` | `#FFB4AB` | `errorContainer` | `#93000A` |
| `onErrorContainer` | `#FFDAD6` | `success` | `#9AD58E` |
| `warning` | `#FFB86B` | | |

These are the Figma file's dark values.

The shell's defaults are black with Nord blue accents (`utils/Palettes.qml`; see DESIGN.md "Theme"), so on screen the colors differ from the PNGs. Match **roles**, not hex: if Figma uses `primaryContainer`, the code uses `Colors.primaryContainer`. With `Config.theme.fromWallpaper` on, matugen output replaces every role except `surface` and `island`, which stay black.

In `Colors.qml`, each `onX` role is spelled `xFg`: `onSurface` → `surfaceFg`, `onPrimary` → `primaryFg`, and so on. QML rejects properties that start with `on` plus a capital letter.

## Typography and icons

- Text: **Google Sans Flex** (`Appearance.font.family`). Weights used: Regular, Medium, SemiBold, Bold.
- Icons: **Material Symbols Rounded**, ligature names only, always through `MaterialIcon`. Sizes used: 16, 18 (island), 20, 22 (OSD, sliders), 24–40 (panels, media).
- Island clock 15 SemiBold `onSurface`; date 13 Medium `onSurfaceVariant`; labels 12–13 Medium; values 13–16 SemiBold.

## Phase 3 spec — Volume / brightness OSD (frame `05`, node `4:15`), done

| Part | Value |
| --- | --- |
| Shape | 340 × 48, radius 24, fill `island`, 1px `outlineVariant` at 40% inside stroke |
| Position | top center, 6px from the top (same place as the island) |
| Layout | horizontal, padding 0 / 16, gap 12, items vertically centered |
| Icon | 22px, `onSurface`; `volume_off` / `volume_mute` / `volume_down` / `volume_up` by level and mute; `brightness_low` / `brightness_medium` / `brightness_high` for brightness |
| Track | fills remaining width, 6px tall, radius 3, `surfaceContainerHighest` |
| Value fill | `primary`, width = level × track width, animated with `Anim` |
| Number | 13 Medium `onSurfaceVariant`, right-aligned in a 36px box, no `%` sign |
| Behaviour | shows on any change from `Audio` or `Brightness`; hides after `Config.osd.hideDelay` (1500 ms); never takes focus |
| Night light | no OSD; toggling it is reflected only in the quick-settings tile later |

The OSD is a mode of the island (`modules/island/OsdView.qml`): the pill morphs to 340 × 48 and back. Under a fullscreen window it drops in from the top edge. See ISLAND.md, Motion.

## Exporting a frame to `docs/design/`

In Figma: select the frame on the canvas → right panel **Export** → `PNG`, `2x` → **Export**, then save it under the file name from the frame index. Re-export when a frame changes; commit the PNGs with the code that uses them.
