# R1 — Island redesign: hover peek and Control tab

Spec for roadmap item R1, to build before F8. It replaces the bento Overview with a narrow **Control** tab, adds a **hover peek**, and moves the dashboard cards into their own tabs. Everything not mentioned here stays as `docs/ISLAND.md` describes it. Once R1 is merged, fold the final rules into ISLAND.md and keep this file as the design record.

## Why

- The bento Overview opens a 820-wide wall of cards (clock, weather, system, calendar, toggles) for a click that is usually "toggle Wi‑Fi" or "read notifications".
- The clock card repeats the clock already shown in the island.
- Diagnostics and weather are things you look up on purpose, so they belong in their own tabs.

## How the reference shells do it

Both reference shells use the same pattern. hyprism was checked in its source (commit a545398); the second shell, from a YouTube video, was judged from its screenshots.

| | hyprism | Reference shell (video) |
| --- | --- | --- |
| Hover | after ~110 ms, the island widens into one row: workspaces, media strip, weather, Wi‑Fi name, Bluetooth, battery %; closes ~240 ms after leaving; no keyboard | the island grows **taller**: same top line, plus a second line with app name and workspaces, media chip, "All caught up" and status |
| Click | "Hub": date header, 2×3 split tiles (toggle + chevron), volume/mic/brightness chips, media row, notification list with Clear all | control center: pill tiles with round icons, a column of round buttons, big Sound and Display sliders, notification box |
| Big dashboard | desktop widgets on the Bottom layer, not in the island (our F12) | — |

ezshell follows the **taller** peek, because it keeps the clock fixed (balance rule). It follows the **click → control center** model of both.

Reference images in `docs/design/`:

| File | What |
| --- | --- |
| `r1-full.png` | the full reference layout |
| `r1-hovered.jpg` | reference shell: taller hover peek |
| `r1-clicked.jpg` | reference shell: control center (click) |

The inline mock from the planning chat (rest, peek, Control) is the visual target. Where the mock and this file disagree on behaviour, this file wins.

---

## States

```
rest ──hover 150 ms──▶ peek ──leave 250 ms──▶ rest
  │                     │
  └──────click──────────┴──▶ expanded (Control tab, or a deep-linked tab/section)
```

| State | Keyboard | Layer | Size |
| --- | --- | --- | --- |
| rest | none | Top | unchanged (balance rule) |
| peek | none | Top | rest width or `Appearance.island.peek.width`, whichever is larger × `peek.height` |
| expanded | OnDemand | Top (Overlay over fullscreen) | from the size table, per tab or section |

**Priority** (unchanged except for peek): polkit > expanded panel / launcher > temporary modes > **peek** > rest.

- Peek never starts while any panel, temporary mode or polkit prompt is showing.
- If one of those starts while peeking, the peek closes immediately.

---

## Hover peek

### Layout

Two lines inside one shape:

- **Line 1 is identical to rest.** Same workspace indicator, same clock + date, same status icons, at the same positions. The clock must not move by even a pixel between rest and peek.
- **Line 2 is three groups**, laid out by the same balance rule (equal sides, center fixed):

| Group | Content | When empty |
| --- | --- | --- |
| left | focused window's app icon (16) + app name (12 Medium), elided at `peek.appMaxWidth` | "Desktop" in `surfaceVariantFg` |
| center | media chip: art 26 (radius 7), title (12 SemiBold) / artist (11), play/pause button, on `surfaceContainer`, radius 12 | hidden, and the sides still balance |
| right | "All caught up" (12, `surfaceVariantFg`) + `notifications` icon, or "N new" + `notifications_active` in `primary`; DND shows `do_not_disturb_on` + "Do not disturb" | — |

### Tokens

Add these to `themes/IslandTokens.qml`:

| Token | Value |
| --- | --- |
| `peek.width` | 600 |
| `peek.height` | 88 (44 + 44) |
| `peek.radius` | 26 |
| `peek.lineGap` | 0 (line 2 sits right under line 1) |
| `peek.bottomPadding` | 12 |
| `peek.appMaxWidth` | 160 |
| `peek.openDelay` | 150 ms |
| `peek.closeDelay` | 250 ms |

### Behaviour

- **Opening.** A `HoverHandler` on the visible shape starts the open timer. Leaving starts the close timer; re-entering cancels it.
- **Morph.** Peek is a mode in the size table, so the existing morph animates rest ↔ peek. Line 2 fades in after ~40% of the morph and fades out first on close.
- **Clicks:**

| Click on | Opens |
| --- | --- |
| media chip | Media tab; the play/pause button only toggles and doesn't expand |
| notification status | Control, scrolled to the notification center |
| app name | nothing (or overview of windows later, in F10) |
| status icons | their sections, as today |
| workspace dots / special chip | as today |
| anywhere else | Control tab |

- **Not while dragging.** No peek during a drag-and-drop or while a mouse button is held.
- **Config:** `Config.island.hoverPeek` (bool, default true). Off means hover does nothing and clicking works as before.
- **Multiple monitors:** the peek is per screen, on the screen whose island is hovered.

---

## Expanded island

### Tabs

| Tab | Id | Width | Content |
| --- | --- | --- | --- |
| Control | `control` | 440 | tiles, sliders, media row, notification center |
| Media | `media` | as today | unchanged (frame 04 controls) |
| System | `system` | ~720 | system monitor |
| Weather | `weather` (new) | ~560 | current, hourly, 7 days |
| Calendar | `calendar` | ~440 | month grid + clock card |

- `Visibility.tabs` becomes `["control", "media", "system", "weather", "calendar"]`.
- **Old name:** `"overview"` stays accepted everywhere (IPC, keybinds, `open`) as an alias for `"control"`, so existing binds keep working.
- **Sizing:** each tab's width and height come from the size table, so switching tabs morphs the size. Heights follow content, capped at `Appearance.island.dashboard.maxHeight`; inside that the content scrolls.
- **Header (unchanged):** the tab row with the sliding underline on the left, battery % and power on the right.

### Control tab

Top to bottom, padding 12, gap 8:

**1. Tiles.** A grid of two flexible columns plus one 44-wide column of round buttons.

| Row | Column 1 | Column 2 | Round button |
| --- | --- | --- | --- |
| 1 | Wi‑Fi (SSID / Off) | Do not disturb ("Focus") | Lock |
| 2 | Bluetooth (device / Off) | Night light (temperature / Off) | Settings |
| added in F8 | Game mode | Keep awake | — |

- **Pill tile:** height 44, radius 22, `surfaceContainerHigh`.
  - A round icon (30, radius 15) on the left: `surfaceContainerHighest` when off, `primary` with `primaryFg` icon when on.
  - Title 13 Medium, subtitle 11 `surfaceVariantFg`.
- **Tile rule (unchanged):**
  - clicking the round icon toggles;
  - clicking the body or the chevron opens the detail section;
  - right-click opens detail too.
- **Round button:** 44×44, radius 22, `surfaceContainerHigh`; filled `primary` when its state is on.
- **Reuse:** `QuickToggles.qml` / `Tile.qml` become this grid; don't build a parallel tile.

**2. Sliders.** Each slider is a card on `surfaceContainerHigh`, radius 16, padding 8 / 12.

| Slider | Label row | Track | Chevron opens |
| --- | --- | --- | --- |
| Sound | "Sound" + output device name (elided) | 20 high, radius 10, `surfaceContainerHighest`; fill `primary`; icon inside the fill at the left (`volume_off/mute/down/up`), `primaryFg` | audio section |
| Display | "Display" | same; icon `brightness_low/medium/high` | display section (new: brightness + night light temperature + schedule from F8) |

- Dragging and scrolling change the value live.
- Clicking the icon inside the Sound track toggles mute.
- The mic is not a slider here. It stays in the audio section; mic mute is a round button only if room allows.

**3. Media row.** Shown only while a player is active; otherwise it takes no space.

- Art 36 (radius 9), title 12 SemiBold, artist · player 11, and previous / play-pause / next.
- `surfaceContainerHigh`, radius 16, padding 8.
- Clicking the art or the text opens the Media tab.

**4. Notification center.** Fills the rest, up to the tab's max height, then scrolls.

- **Header:** "Notifications" (13 SemiBold), the count (12 `surfaceVariantFg`), and on the right "Clear all", which asks for a second click.
- **List:** the existing `NotificationList.qml`. Each item:
  - app icon 28 (radius 8);
  - app · relative time (11);
  - summary (13 Medium) and body (12, up to 2 lines);
  - ✕ on hover.
  - Clicking an item runs its default action. Grouping by app is optional; if added, keep it collapsible.
- **Empty state:** a `notifications` icon, "All caught up" (13) and nothing else. The section stays at a small fixed height.
- **DND:** a small "Do not disturb is on" line above the list.
- **Deep link:** `panels open notifications` opens Control scrolled to this list. It isn't a separate section.

**Removed from the first tab:** ClockCard, WeatherCard, SystemCard and the mini month. Delete any card that ends up unused.

### System tab: system monitor

A two-column grid of cards (`surfaceContainerHigh`, radius 16, padding 12, gap 8), hyprism desktop-widget style:

| Card | Content |
| --- | --- |
| Performance | CPU % and RAM % each with a sparkline of the last ~60 samples |
| Network | SSID at the top right; download and upload rates with sparklines |
| Storage | root (and home if separate): used / total, a bar |
| Sensors | CPU, GPU (if available), NVMe, Wi‑Fi temperatures |
| System | kernel, uptime, session (Hyprland / Wayland); later the updates count (F9) |

- Sparklines are a small component (`components/Sparkline.qml`, a `Shape` or `Canvas`), fed from a ring buffer in `SysInfo`.
- `SysInfo` polls **only while the System tab is open**, as now.
- Sensor temperatures are read through `FileView` on hwmon, with no new tools.

### Weather tab (new)

- **Current:** a big icon (40), temperature (40 SemiBold), condition, location, feels-like, humidity, wind.
- **Hourly:** the next 12 hours as capsules (time, icon, temperature), with the current hour on `primaryContainer`.
- **Next 7 days:** one row per day with the day name, icon, a min/max range bar and min/max values.
- **Data:** from the existing `Weather` service; extend it if the hourly or daily data isn't fetched yet. It refreshes only on open, if the data is older than the refresh interval.

### Calendar tab

The month grid (today highlighted, month navigation) plus the clock card, moved here from the old Overview.

---

## State, IPC and config changes

- **`Visibility`:**
  - `tabs` as above;
  - `"overview"` → `"control"` alias inside `open`/`toggle`;
  - a new `peek` state per screen (or a `peekScreen` string), not stored as a panel.
- **IPC:**
  - `panels open control|media|system|weather|calendar|notifications` (`overview` still works);
  - `island peek on|off` for testing the peek without a mouse.
- **Config:** `island.hoverPeek` (bool).
- **Keybinds** (in docs/HYPRLAND.md): the existing overview bind keeps working through the alias. Suggest a notification-center bind (e.g. Super+N) only if it doesn't clash.

## Motion

- Rest ↔ peek uses the same interruptible morph and curves as every other mode (expand overshoot, collapse without).
- Tab switches: content cross-fades, and the size morphs between the size-table entries.
- Sliders, tile on/off and notification add/remove animate with `Anim`/`CAnim`. A dismissed notification slides out and the list closes the gap.

## Build steps (stop after each for testing)

1. **Control tab:**
   - tiles grid, sliders, media row;
   - rename overview → control, with the alias;
   - remove the old Overview cards from the first tab;
   - add the size-table entry.
2. **Notification center** inside Control, with the empty state, Clear all confirmation and the `panels open notifications` deep link.
3. **Hover peek:**
   - timers, line 2, deep links, config switch and the `island peek` IPC;
   - verify the clock doesn't move.
4. **System and Weather tabs:**
   - sparkline component and SysInfo ring buffer;
   - Weather hourly/daily;
   - Calendar gets the clock card;
   - delete unused cards.

## Done when

- [ ] Clicking the island opens Control at about 440 wide.
- [ ] Wi‑Fi, Bluetooth, DND and night light tiles toggle with the icon and open details with the body.
- [ ] The Sound and Display sliders work by drag and scroll.
- [ ] The media row appears only while playing.
- [ ] The notification center lists, dismisses and clears (with confirmation), and shows "All caught up" when empty.
- [ ] Hovering the resting island shows the peek after about 150 ms and hides it about 250 ms after leaving.
- [ ] Line 1 of the peek is pixel-identical to rest, and the clock never moves.
- [ ] Peek is skipped while anything else is showing.
- [ ] Every peek click target opens what the click table says.
- [ ] System, Weather and Calendar tabs show their content, and switching tabs morphs smoothly.
- [ ] `SysInfo` stops polling when the System tab closes.
- [ ] `panels open overview` still works.
- [ ] No unused cards are left behind.
- [ ] qmlformat and qmllint are clean, and the log is clean.
- [ ] Screenshots of rest, peek and every tab go to the user.
