# 09 · Decisions and build order

## Decisions

Settled on 2026-11-12. The owner's original answers are kept verbatim at the
bottom of this file; the table records how each was applied.

| # | Question | Decision | Written into |
| --- | --- | --- | --- |
| 1 | Project name | **ezshell**: config directory, IPC appid, `ezshell-` layer namespaces, state paths | 01, 06 |
| 2 | Fonts and icons | **Geist** (vendored) **+ Material Symbols Rounded** (system package `ttf-material-symbols-variable`). SF was dropped; Lucide and then Phosphor were tried and replaced | 05 |
| 3 | Reserve screen space | **Yes**, through a separate `Reserve` window that never references the island's size. OSD still shows over fullscreen | 02, 06 |
| 4 | OSD while the control panel is open | **Not shown** | 02, 03 |
| 5 | Monitors | **One island**, on a configurable monitor | 02 |
| 6 | Lock | **Own minimal lock screen** (clock + background), with the island clock growing into place | 04 |
| 7 | Click on the island | Opens the control panel | 02 |
| 8 | Session actions | **Their own sheet** | 03 |
| 9 | Appearance | **Light first**; dark defined alongside; `matugen` later. The island follows the scheme (white in light, black in dark) | 05 |
| 10 | Overshoot | Bezier tokens; revisit springs only if the morph feels wrong | 05 |

### Consequences worth knowing

- **Light theme vs. a black island (9).** A Dynamic-Island-style black shape
  needs light-on-dark content while the rest of the shell is dark-on-light. So
  palettes are objects that can be applied to a subtree, both are built from the
  start, and the island's own colour is left to decide on screen.
- **Material Symbols comes from the system (2).** It is one variable font
  (fill, weight, grade, optical size), so fill animates and icons are drawn by
  name. A vendored copy clashed with the installed one and drew wrong icons.
- **One island (5).** Views and OSDs appear on the island's monitor even when
  another monitor has focus.
- **Lock transition (6).** Lock surfaces are separate from the island window, so
  the "travelling clock" is the lock screen drawing an identical clock that
  starts at the island's position. The `Clock` component and `Label` must
  therefore support smoothly animated size from the day they are written.
- **Toasts under the control panel (4).** Level OSDs are dropped; toasts about
  things the control panel does not show are held until it closes.

## Still to verify

- Material Symbols weight against Geist regular and semibold at the icon sizes
  in 05; adjust the pairing or the sizes if they do not balance.
- Geist metrics against Apple's line heights.
- Animated font size on `Label` stays crisp and does not jitter (needed for the
  lock transition and the `hovered` clock).
- `ShapePath` inverse corners at the idle size, with radius flattening.
- Mask region tracking the animated shape.
- `HyprlandFocusGrab` + `OnDemand` keyboard focus on Hyprland 0.57.
- `Quickshell.Networking` against NetworkManager with the iwd backend: checked.
  The Wi-Fi device reports connected, but no network in its list is marked
  connected. `Network` works around it by asking `nmcli` for the name. Connecting
  and scanning through this API are still untested (phase 7).

## Known issues and things to watch

Behaviour that is intended today but likely to cause confusion or bugs later.
Check this list before building anything that touches the same area.

- **Nothing but the OSD can show while a window is fullscreen.** The island
  pulls itself above the screen edge when the focused workspace has a
  fullscreen window, and only a view marked `showOverFullscreen` (the OSD) may
  come down. It then floats as a pill, as the
  border it would hang from is hidden (see 02). So a keybind or IPC call that opens the control panel, the
  launcher or any sheet during fullscreen changes `IslandState` but shows
  nothing: the view is open, invisible, and holding keyboard focus and the
  outside-click grab if it asks for them. Risks: keys appear to stop working in
  the fullscreen app until the invisible view is closed; a sheet opened during
  fullscreen pops into view when fullscreen ends. Likely fixes when this is
  taken on: refuse to open views while fullscreen, or let chosen views (the
  launcher) show over fullscreen, or close any open view when fullscreen
  starts. Anything that opens a view (launcher keybind, session sheet,
  notification click) must be tested in fullscreen.
- **The island window is always on the overlay layer**, above every other
  layer surface, because switching layer at runtime had no effect. Anything
  else that expects to sit on top (a lock screen is separate and unaffected,
  but another tool's overlay is not) will be under the island's shape.
- **A restored notification cannot be acted on.** Notifications are saved and
  come back after a restart, but the app that sent one is no longer connected
  to the shell, so its own buttons are not shown for it. An image the server
  held only in memory comes back as the app's icon.
- **A banner does not show while a panel or sheet is open.** The notification
  is still added to the list; it is just not announced.
- **The emoji list may be newer than the emoji font.** `assets/symbols.tsv`
  comes from emojibase's latest data; an emoji the installed Noto Color Emoji
  does not have yet shows as a blank or a box in the launcher. Update the list
  with `scripts/fetch-symbols.py`; the font is a system package.
- **The clipboard mode depends on something feeding cliphist**
  (`wl-paste --watch cliphist store`), which the shell does not start.
- **The lock screen has only been unlocked by a test.** Locking, the clock
  travelling out and back, and release were checked with a timed release in a
  copy of the shell. Typing the real password through PAM has to be tried by
  hand, with a TTY ready the first time.
- **Locking by itself is only partly tried.** Locking after idle was checked
  with a harmless command in place of the lock. Locking before sleep, on
  `loginctl lock-session`, turning the screens off and suspending have not
  been run. A lock request from any session locks this one.
- **Choosing a window or an area has not been tried with a real pointer.**
  The chooser opens on the frozen picture and lists the right windows; the
  whole-screen screenshot and screen recording were run for real. Recording
  an area passes a position on the whole desktop in pixels, untested with
  several monitors or a scale other than 1.
- **Colouring other programs is off until switched on**, and Hyprland and GTK
  write files Caelestia also writes: with both shells running, the last one to
  change wallpaper wins. Colouring open terminals has not been run.
- **The switch and slider thumbs are grey in generated dark colours**, not
  white: Material has no white there.
- **The screens-off step toggles.** Hyprland's Lua dispatcher would only
  toggle reliably, so the shell reads the state first; something else turning
  the screens off at the same moment could turn them back on.
- **If the shell crashes while locked, the screen stays locked with no
  password field** until the shell is started again from a TTY and locked
  again.
- **Session actions over IPC do not ask for confirmation.**
  `session logout`, `reboot` and `poweroff` act at once; only the session view
  asks twice. Do not bind them to a key that is easy to hit.
- **Log out ends the session with `loginctl terminate-session`**, not through
  Hyprland, because the name of Hyprland's exit dispatcher in Lua mode was not
  confirmed. It has never been run.
- **The shell draws the wallpaper on every screen**, and covers whatever else
  draws one. Turn it off with `wallpaper.enabled` if another tool should.
- **The thumbnail cache is never pruned.** A thumbnail stays in
  `~/.cache/ezshell/thumbnails` after its picture is deleted or moved. They
  are about 15 KB each; delete the folder to rebuild it.
- **Changing a setting rewrites the whole settings file** from what the shell
  knows, so comments and unknown keys in a hand-edited `config.json` are lost
  the first time the settings window changes anything.
- **Turning "Show the island" off in settings leaves no island to turn it
  back on from.** The settings window stays open; after closing it, use
  `qs -p . ipc call settings open island` or edit the file.
- **Sliders in settings raise the OSD.** Changing volume or brightness in the
  settings window shows the level on the island too, as any other change does.
- **Forget has no confirmation** for a Wi-Fi network or a Bluetooth device.
- **Volume and brightness raise both the OSD and the `default` pulse**, so the
  status row shows for a moment after the level bar leaves.

## Build order

Components first. The island is not started until the component library and the
motion primitives have been inspected in the gallery and are reusable as they
stand.

### Part A — scaffold and components (current focus)

Part A (phases 0 to 4) is done (2026-11-12).

| Phase | Deliverable | Done when |
| --- | --- | --- |
| 0 · Scaffold and assets | Git repo, `shell.qml`, `.editorconfig`, `.qmllint.ini`, `.qmlls.ini`, directory skeleton; Geist and the icon font downloaded into `assets/fonts/` with licences; the icon name helper in `utils/`; `Tokens` (type, both palettes, spacing, radius, motion); `Config` | `qs -p .` starts clean and lint passes |
| 1 · Foundations and gallery | `Anim`, `ColorAnim`, `Label`, `Icon` (animated `filled`, weight, crossfading swaps), `Surface`, `Pressable`; gallery window with sidebar, toolbar (palette, font scale, animation speed, reduce motion); typography, colour, icon and motion-token pages | Every token is visible in the gallery; switching palette crossfades |
| 2 · Controls | `Button`, `IconButton`, `ToggleTile`, `Switch`, `Slider`, `LevelSlider`, `SegmentedControl`, `Separator`, `Badge`, `ProgressBar`, `Spinner`, `Tooltip` | Each has a gallery page with all variants and states and feels right under hover, press and keyboard |
| 3 · Inputs and containers | `TextField`, `SearchField`, `ScrollView`, `List`, `ListRow` | A scrolling, keyboard-navigable list with a search field works in the gallery |
| 4 · Transitions | `Reveal`, `Morph`, `PageStack`; motion lab demos swapping content of different sizes, interrupting midway, slow motion | A `Morph` in the gallery resizes and crossfades between arbitrary contents smoothly and can be retargeted mid-flight |

Phase 4 is the hand-over point: `Morph` proves the island's resize-and-crossfade
in an ordinary window. What it cannot prove is the layer-shell side (the fused
shape, the input mask, focus grab, fullscreen), which is first exercised in
phase 5.

### Part B — the island and features

Phases 5 to 14 are done (2026-11-13). Phase 14 is specified in
[10-phase-14.md](10-phase-14.md). The gallery window the early phases were built in was removed on 2026-11-14;
the phase table below still mentions it as history.

| Phase | Deliverable |
| --- | --- |
| 5 · Island core | Window, `Reserve`, shape, mask, `IslandState`, `ViewHost` with placeholder views, monitor selection |
| 6 · States | Core services; `idle`, `default`, `hovered`; pulse and hover logic |
| 7 · Control panel | Root page, pages (`wifi`, `bluetooth`, `audio`, `nightlight`) |
| 8 · OSD | `Osd` service, level and toast, fullscreen layer switch |
| 9 · Notifications | Server, item component, lists, sheet, DND |
| 10 · Launcher | Apps, actions, clipboard, emoji |
| 11 · Sheets and background | Background module, wallpaper selector, calendar, session |
| 12 · Settings | Floating window (tier 3 components built here) |
| 13 · Lock screen | `WlSessionLock`, PAM, clock transition |
| 14 · Shortcuts, special workspaces, capture, theming | See [10-phase-14.md](10-phase-14.md) |

## My answers to open questions
1. Project will be called ezshell.
2. Lets scratch the SF and fully commit to Geist and Lucide Icons. Also check if its possible to install both locally so no need for packages.
3. Lets reserve a space. Make sure the file for the bar is not the one being referenced for the space and its another entity so that when the bar expands or changes sizes it doesnt change the spacing. Also there will be instances that for example OSD wil show on top of fullscreen apps so make sure it works.
4. If the control panel is open no need for the osd since we can already see the changes in the control panel. 
5. We can make it so that island cam be only on one and we can configure which monitor to have it.
6. We create our own lockscreen. We make it minimal like how the Mac does it with just a clock and a background. It should animate smoothly like the clock from the Bar will transition to be bigger and position itself.
7. Clicking the bar/island will open the controlpanel
8. Their own sheet so it would be clean and focused.
9. maybe configure it as light for now since our basis will be Apples HIG design when creating components so lets go light for now but it can be adjusted in the future when we implement dynamic theming using matugen.
10. Go with recommened.
