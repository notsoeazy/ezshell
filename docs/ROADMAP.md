# ezshell — Feature Roadmap

Nov 6, 2026. Phases 1–6 and enhancements E1–E6 in `docs/DESIGN.md` are done. This file lists the **next features in build order**, with the decisions already made for each. Work on one feature at a time, top to bottom, unless the user picks another.

The research behind these choices comes from hyprism (commit a545398), caelestia, end-4 "ii" and the Quickshell 0.3.2 source.

## How to work on a roadmap feature

1. **Read before planning:** this feature's section, `AGENTS.md`, `docs/DECISIONS.md`, `docs/MEMORY.md`, the relevant parts of `docs/DESIGN.md` and `docs/ISLAND.md`, and the code the feature touches.
2. **Plan, then wait.** Post a short plan (files to add or change, one line each) and wait for the user's OK.
3. **Service and IPC before UI.** Give the user the terminal commands to test the service, and wait for confirmation before building UI on it.
4. **Native first.** No Python, no daemons of our own, and no third-party wallpaper tools. An external CLI tool runs only through one `Process` owned by one service, and only when Quickshell or Qt can't do the job.
5. **Clipboard:** never use `Quickshell.clipboardText`. It is empty unless a Quickshell window has focus. Use `wl-copy` / `wl-paste`.
6. **Where files go:**
   - state that survives a restart (recents, history): `~/.local/state/ezshell/*.json`, through `FileView` + `JsonAdapter`;
   - temporary images: `$XDG_RUNTIME_DIR/ezshell/`, mode 700, never `/tmp`.
7. **Keybinds and Hyprland rules go in `docs/HYPRLAND.md`**, in the user's Lua style. Never edit the user's Hyprland config.
8. **Finish:**
   - qmlformat and qmllint, and a clean `qs` log;
   - mark the feature done in the table below, and note anything left undone in its section;
   - update `AGENTS.md` if the feature adds a service, a shell-out or a rule;
   - record the user's decisions in `docs/DECISIONS.md` and update `docs/MEMORY.md` (open items, untested);
   - commit.

Test wallpapers live in `~/Pictures/Wallpapers/` (the default `Config.wallpaper.folder`). Use them for every wallpaper and theming test.

## Order and status

| # | Feature | Size | Status |
| --- | --- | --- | --- |
| F0 | Make room: split the files near 250 lines | S | done |
| F1 | Wallpaper selector in the island, native transitions | M | done |
| F2 | Launcher providers: registry, `>` actions | M | done |
| F3 | Clipboard history (`;`) | M | done |
| F4 | Emoji, symbols and kaomoji (`:`) | S | done |
| F5 | Polkit agent in the island | M | done |
| F6 | Screenshots and screen recording | M | done |
| F7 | Generic OSD and capture feedback (tasks dropped) | S | done |
| R1 | [Island redesign: hover peek and Control tab](ISLAND-R1.md) | L | done |
| F8 | Quick utilities (external brightness skipped) | S each | done |
| F9 | Keybind cheat sheet (updates skipped) | S | done |
| F10 | Window switcher (Super+Tab) | M | done |
| F11 | Theme presets and matugen templates for other apps | M | next |
| F12 | Desktop widgets (optional) | L | |

---

## F0. Make room

Several files are at the 250-line limit, and the next features add island modes. Split these first, with no behaviour change. Confirm the island looks and animates the same afterwards.

| File | Lines | Split idea |
| --- | --- | --- |
| `modules/island/Surface.qml` | 246 | Move per-mode size logic into one mode table (name → width/height source/radius), so a new mode is one table entry, not new `if` branches. The `launcher` special cases become table entries. |
| `services/Theme.qml` | 249 | Role map and scheme list into a `utils/` singleton; matugen run and contrast fixes stay. |
| `themes/Appearance.qml` | 247 | Split the island and settings token groups into their own inline components, or a second file under `themes/` if inline components can't stay under 250. |
| `services/Wifi.qml` | 246 | Saved/hidden-profile `nmcli` work into a helper the service owns. |

Done when every file is under about 200 lines and `panels toggle overview` / `launcher` / OSD behave exactly as before.

**Done.** Before/after screenshots of rest, OSD, launcher, overview, system and Wi‑Fi match; `theme status` and `wifi status/saved` give the same output.
- `Surface.qml` (158): `sizeFor(mode)` is the mode table (one `case` per mode, sections share one). The mode layers moved to `ModeLayers.qml` (115), which reports the content-driven sizes. Corner radius stays one rule for all modes.
- `Theme.qml` (193): role map, scheme list, contrast pairs and the JSON → palette mapping moved to `utils/Matugen.qml`.
- `Appearance.qml` (106): the island group moved to `themes/IslandTokens.qml` (143); `Appearance.island.*` paths are unchanged.
- `Wifi.qml` (196): saved/hidden-profile `nmcli` work moved to `services/WifiProfiles.qml` (86), a non-singleton helper only `Wifi` creates.

## F1. Wallpaper selector

Wallpapers are drawn by the shell itself. No swww, awww, hyprpaper or imagemagick.

**Already there:**
- `modules/wallpaper/Wallpaper.qml`: a Background-layer window per screen; an `Image` decoded at screen size; IPC `wallpaper set/get`.
- `Config.wallpaper.path` and `Config.wallpaper.folder` (default `~/Pictures/Wallpapers`).
- `modules/settings/WallpaperPicker.qml`: a `FolderListModel` grid with `sourceSize` thumbnails, used by the Appearance page.
- `Theme` regenerates colors through matugen when the wallpaper changes.

**To build:**

1. **Shared grid.** Move the thumbnail grid into `components/WallpaperGrid.qml`, so the settings page and the island use the same one. It takes `folder`, `selected` and a filter string as properties, reports `picked(path)`, and never reads Config itself.
2. **Island section `wallpapers`.** A wide grid with a search field.
   - Opened by `panels open wallpapers` or Super+K.
   - Arrow keys move and Enter applies. The current wallpaper has a check mark.
   - Hovering or selecting shows the name. An optional palette preview uses `Theme.previewWallpaper`, which already exists.
   - Add `wallpapers` to `Visibility`'s section list and to the F0 mode table.
3. **Native transitions.** `Wallpaper.qml` keeps two `Image`s and cross-fades from the old to the new once the new one has loaded (`status === Image.Ready`), so it never flashes black.
   - `Config.wallpaper.transition`: `fade` (default), `wipe` or `none`. Wipe is a moving `OpacityMask`/clip, or a small `ShaderEffect` if that's simpler.
   - The duration goes through `Appearance.anim.scaled`.
4. **Fill mode:** `Config.wallpaper.fill` is `crop` (default), `fit` or `center`.
5. **More IPC:** `wallpaper random`, `next`, `previous` (in folder order) and `list`. Keybind Super+Alt+K for random.
6. **Optional slideshow:** `Config.wallpaper.interval` in minutes; 0 means off. Use a `Timer` that runs only while the interval is above 0.
7. **Large folders.** `sourceSize` thumbnails plus `Image.cache` are enough for a few hundred files. Note how the grid behaves with the user's real folder; don't add a disk thumbnail cache unless it's slow.

8. **Single-row strip** (added during F1): the island section is one row with the selection always centered; ←/→, the wheel and touchpad swipes slide it.

**Done.**
- `Wallpapers` service: one `find -L` over the folder and its subfolders (hidden ones skipped), on start, on a folder change and when a picker opens; IPC `wallpaper set/get/random/next/previous/list/rescan`.
- `WallpaperView`: two slots per screen, switching only once the new image is `Ready`; fade, wipe or none; crop, fit or center. Rapid switches cut the running transition short and land on the newest.
- `components/WallpaperGrid.qml`: a growing grid in Settings, a centered strip in the island. Settings also has Transition, Fill and Slideshow rows.
- Slideshow: `Config.wallpaper.interval` minutes, next in folder order; the timer runs only while it's above 0, and any change restarts the interval.
- The palette preview in the island was skipped (Settings has it).
- Large folders, tested with 300 generated 1440p images in 6 subfolders: the scan takes 5 ms and the strip adds about 7 MB. The Settings grid creates every thumbnail (about 110 MB and 1 s of CPU for 300), like the Flow it replaced.
- Not checked: a second monitor, and the user's real folder (still downloading at the time).

**Done when:**
- picking from the island and from settings both apply with a smooth cross-fade on every monitor;
- colors regenerate;
- `wallpaper random` works from a terminal;
- the shell never shows a black frame between wallpapers.

## F2. Launcher providers

**Done.** The launcher serves several providers, picked by the prefix typed first. Visual or modal features (wallpapers, polkit, screenshots) stay out of the launcher.

- **Where:** `modules/launcher/` (moved out of `modules/island/`): `Launcher.qml` (the view the island hosts), `Registry.qml`, `Provider.qml` and one file per provider.
- **Provider:** `prefix` (`""` for apps), `name` and `icon` for the hints, `emptyText`, and `items`, computed from `query` (the text after the prefix, set by the Registry only on the active provider). Rows are `{ key, title, subtitle, icon | image }` plus whatever `activated(item, modifier)` needs. Providers call services; any `Process` stays in a service.
- **Adding a provider:** one file plus one entry in `Registry.providers`; `Launcher.qml` never changes.
- **List:** up to `maxResults` rows show and longer lists scroll. Typing resets the selection; a row that only changes keeps it.
- **IPC:** `launcher open <prefix>` (target in `state/Visibility.qml`) opens with the prefix typed, or retypes it in an open launcher. With nothing typed, the footer lists the prefixes; clicking one types it.

| Prefix | Provider | Service | Feature |
| --- | --- | --- | --- |
| none | apps | `Apps` (existing) | F2 |
| `>` | actions (caelestia style): open island sections and settings pages, toggles (Wi‑Fi, Bluetooth, do not disturb, night light, keep awake), random wallpaper, session; log out, reboot and power off take a second Enter | existing services and `Visibility` | F2 |
| `;` | clipboard history | new `Clipboard` | F3 |
| `:` | emoji, symbols, kaomoji | new `Emoji` | F4 |

- **Dropped at the user's request:** the `=` calculator (`qalc`) and the run-a-shell-command provider.
- **Later:** once sections inside the expanded island get keyboard selection, actions can deep-link into them (e.g. a Wi‑Fi network).

## F3. Clipboard history

**Done.** The user's workflow: Super+V opens the history, Enter copies, Ctrl+V pastes.

- **Recording stays in Hyprland** (`wl-paste --type text|image --watch cliphist store` in `execs.lua`), so it keeps working while the shell restarts. The shell runs no watcher.
- **`Clipboard` service:** reads `cliphist list` at start, when the `;` list opens, and after each change made from the shell. `copy(id)` (`cliphist decode | wl-copy`), `remove(id)`, `wipe()`; changes run one at a time. Commands go through `sh -c` with the id as an argument. Images are recognised from cliphist's `[[ binary data … ]]` preview (size, format, resolution).
- **Images:** decoded on demand, only for rows on screen and one at a time, into `$XDG_RUNTIME_DIR/ezshell/clip/<id>.png` (mode 700). The folder is emptied at start; remove and wipe delete their files.
- **Launcher provider `;`:** newest first, filtered on the preview text; Enter copies and closes, Delete removes, "Clear history" (last row, or `;clear`) takes a second Enter. `Provider` gained `hints`, `removable`/`removed(item)` and `preview(item)` for this.
- **IPC:** `clipboard refresh`, `list`, `copy(id)`, `remove(id)` (`delete` is reserved in JavaScript), `wipe`, `status`. Keybind Super+V → `launcher open ";"`.
- **Dropped at the user's request:** incognito (not needed), and Alt+Enter paste with `wtype` (Ctrl+V does it).
- **Not checked:** the password-manager hint (no KeePassXC installed); cliphist itself skips copies marked `x-kde-passwordManagerHint`.

## F4. Emoji, symbols and kaomoji

**Done**, in caelestia's spirit (its `caelestia emoji` data set), shown as a grid. Enter copies and the user pastes with Ctrl+V: no Alt+Enter typing, no `wtype`, no skin tones.

- **Data, committed so the shell works offline:** `assets/emoji.tsv` (`kind`, `text`, `name`, `words`, `font`; 12,836 rows): 1,914 emoji, 243 symbols, 62 kaomoji, 10,617 Nerd Font glyphs.
  - Built once by `scripts/emoji-gen.py` (run by hand, never by the shell; needs `fontTools`) from emojibase `compact.raw.json` (MIT; names and tags from Unicode CLDR), Nerd Fonts `glyphnames.json` (MIT) and the hand-written `scripts/emoji-extra.tsv` (arrows, math, currency, typography, Greek, kaomoji).
  - **Hidden when the fonts can't draw them:** emoji are checked against Noto Color Emoji, multi-character ones against its ligatures; the rest against every installed font. Left out: the 9 Emoji 17 characters the installed font lacks. Re-run after a font update.
  - **Font column:** symbols and kaomoji that Inter can't draw name a family that can (Noto Sans Kannada for ಠ_ಠ). Without it Qt tries Inter first for complex scripts and logs "OpenType support missing" on every draw.
- **`Emoji` service:** loads the file once with `FileView`; search ranks name start, name word, search word, then contains, accent-insensitive (`Fuzzy.fold`), emoji first; loose in-order matching only when nothing else matches, never over the Nerd Font names. About 10–30 ms per query. Recents (last 30) in `~/.local/state/ezshell/emoji.json`, written on the first pick. `copy(text)` goes through `Clipboard.copyText` (`wl-copy -- <text>`). IPC `emoji search(text)`, `copy(char)`, `recents`.
- **Launcher grid support:** `Provider.layout` (`"list"` or `"grid"`), `cellWidth`, `chips`/`chip` (Tab and Shift+Tab), `status(item)` for the footer. Rows and cells live in `LauncherRow.qml` and `LauncherCell.qml`; apps, actions and clipboard looked the same before and after.
- **Provider `:`:** a grid; with nothing typed, recent picks first, then everything (emoji, symbols, kaomoji, Nerd Font glyphs). Chips by kind: All, Recent, Emoji, Symbols, Kaomoji, Nerd Font. Kaomoji get wide cells under their chip and are cut short elsewhere. The footer names the selection; Enter copies, shows "Copied" for 0.6 s and closes. `>` also has "Emoji & symbols" and "Clipboard history".
- **Not done:** emoji category chips (Smileys, People, …) need a category column in the generator; skin tones (not wanted).
- **Keybind:** Super+Period → `launcher open ":"`, replacing caelestia's emoji picker.

## F5. Polkit agent in the island

**Done.** Polkit password prompts (pkexec, GUI admin actions) show in the island, replacing polkit-gnome.

- **Quickshell support:** confirmed on 0.3.1 (`Quickshell.Services.Polkit`). Polkit allows one agent per session: while polkit-gnome runs, ezshell's agent fails to register (two Quickshell warnings in the log) and polkit-gnome keeps answering. HYPRLAND.md §7 has the line to remove.
- **`Polkit` service** (force-loaded): `registered`, `active`, `state` (`idle | prompt | checking | failed`), the request's `message`, `actionId`, `iconName`, `identities`, `selectedIdentity`, `inputPrompt`, `responseVisible`, `supplementaryMessage`/`supplementaryIsError`; `submit(response)`, `cancel()`, `selectIdentity()`. IPC `polkit status` and `polkit cancel` only; never a submit.
- **Quickshell 0.3.1 bug, worked around:** its agent pops the active request off its queue, so a second request replaced the open one and the first was never answered (its pkexec hung). The service keeps replaced requests and shows them after the newer one: newest first, none dropped. Rare race left: a kept request that times out on polkit's side while a newer one shows makes Quickshell clean up the newer one.
- **Island:** a tier above panels (`Surface.mode`: polkit, then panels, then temporary modes), on the monitor focused when the request arrives. `Visibility` isn't touched and the panel underneath stays loaded, so the launcher's text and the open section come back as they were. While it shows: Overlay layer, Exclusive keyboard, clicks outside and workspace changes don't close anything.
- **Prompt (`PolkitView.qml`):** lock icon, message, action id, identity picker when there's more than one, password field (hidden unless `responseVisible`, with a show toggle), Cancel and Authenticate; Esc cancels, Enter submits; a wrong password shakes and shows polkit's message.
- **Security:** the field is cleared right after `submit()`, on cancel, for each new request and when the view goes away; the response is never stored, logged or sent over IPC.
- **faillock:** cancelling a request after PAM asked for the password counts as a failed login (`pam_faillock authfail` in `system-auth`); three in a row lock the account for 10 minutes, the ezshell lockscreen included. Test with the real password, and don't script cancels.
- **Tested:** request delivery, cancel, queued requests and the prompt over the launcher and a section (scripted); passwords, keys and the lock screen by the user, who reported it works.

## F6. Screenshots and screen recording

**Done.** Every capture is an IPC call (target `capture`), so binds and launcher actions just call it.

- **`Capture` service** (force-loaded; every capture process lives here; paths and geometry go to `sh -c` as arguments):
  - `screenshot(mode)`, mode `region | window | monitor | full`: `slurp` for a region (Esc does nothing), the active window from `hyprctl -j activewindow` at that moment, the focused output, or all outputs; `grim` saves `screenshot_<time>.png` to `Config.capture.screenshots` (default `~/Pictures/Screenshots`, created when missing) and `wl-copy --type image/png` copies it.
  - `record(mode)`, mode `region | window | monitor`, with **gpu-screen-recorder** (installed, GPU-encoded, what caelestia used; chosen over the roadmap's wf-recorder, which isn't installed): the monitor's refresh rate, `-a default_output` when `Config.capture.audio` is on, `recording_<time>.mp4` in `Config.capture.recordings` (default `~/Videos/Recordings`). `stop()` sends SIGINT, which finishes a playable file. It takes 1–2 s to start capturing.
  - `toggle(mode)`, `setAudio(bool)`, `screenshotIn` / `recordIn(mode, ms)` (after a pause, so a menu can close first), `status`. Properties: `busy`, `recording`, `phase` (`selecting | starting | recording`), `lastShot`, `settle`.
  - Hyprland reports no screencast for gpu-screen-recorder (it reads the GPU), and `-w portal` would ask for a share picker each time, so `Capture.recording` drives the island's recording indicator itself.
- **Feedback in the island:** "Drag to select · Esc to cancel" while slurp is up (the shot waits `Capture.settle` for it to clear); "Starting recording…" with a pulsing dot until gpu-screen-recorder reports its encoder, then "Recording" briefly; after a screenshot, the "Saved · Copied" mode with a thumbnail that pops in. The recording indicator (red dot + stop icon) stops the recording when clicked.
- **Notifications:** sent with `notify-send` (one waiting process each, so older ones keep working buttons) with an `x-ezshell-capture` hint, so they go straight to the list instead of a banner. Screenshot: Open, Open folder, Edit (swappy; satty if installed). Recording: Open, Open folder.
- **Island section `capture`** (`panels open capture`, standalone): Screenshot and Record × Region / Window / Screen as cards, a "Record sound" switch, arrows and Enter; a Stop card while recording. Picking collapses the island first.
- **`>` actions:** Capture, Screenshot region / window / screen / all screens, Record screen / region / window (Stop recording while one runs).
- **Later:** a native frozen-screen region picker (a full-screen Overlay window with `ScreencopyView { live: false }`) can replace `slurp`, like caelestia's `screenshotFreeze`.
- **Binds:** recommended in HYPRLAND.md §8, not applied.

## F7. Generic OSD and capture feedback

**Done.** Renamed from "Tasks IPC and generic OSD": the user dropped tasks (no need for them) in favour of feedback for what the shell already does.

- **One message mode** (`modules/island/MessageView.qml`, mode `message`): an icon with a tone (normal, primary, success, error) or a status dot (steady or pulsing), a first line, an optional second line, a small hint on the right, an optional thumbnail that pops in, and optional progress (a bar, or a pulsing one for -1). Sized by its content between `island.message.minWidth` and `maxWidth`, centered. Anything shows one with `Visibility.say(message, duration)`; `Transients` turns each `say()` into the mode and owns the hide timer.
- **Moved onto it** (same look; their files and modes removed): mic mute (`MicView.qml`, mode `mic`), the screenshot thumbnail "Saved · Copied" (`CapturedView.qml`, `captured`), and "Drag to select" / "Starting recording…" / "Recording" (`CapturingView.qml`, `capturing`).
- **New feedback:** "Recording saved" with the file name and length, "Recording failed" / "Screenshot failed" with the tool's reason, "No active window", and "Copied" with the text or the image thumbnail when Enter copies from clipboard history (`;`). `Capture` gained `recorded(path, seconds)` and `failed(what, reason)`.
- **IPC for scripts:** `osd say(icon, text)` and `osd say2(icon, text, subtitle)`, shown for `Config.osd.hideDelay`. Not `show`: `qs ipc call osd show …` parses as `qs ipc show`. Examples in `docs/SCRIPTING.md`.
- **Dropped at the user's request:** the `Tasks` service and its IPC (`add`, `update`, `finish`, `fail`, `remove`, `list`), the progress ring in the island, and the Overview tasks card. A long command reports its end with `osd say2` instead.

## R1. Island redesign: hover peek and Control tab

Spec and design record: [`docs/ISLAND-R1.md`](ISLAND-R1.md); the final rules are in `docs/ISLAND.md`. Done, with these differences from the spec:

- Sparklines are a `Canvas` (`components/Sparkline.qml`), not a `Shape`: `Shape` paths inside the morphing island froze the shell at ~94% CPU when switching to or from System, with either renderer.
- A new `display` detail section (brightness, night light, warmth, schedule), opened from the Display slider's chevron and the night light tile.
- No Power tile: power stays on the header's power button.
- The header's tab gap dropped from 28 to 14 so five tabs, battery and power fit in Control's 440.
- Built in four steps but committed once.

## F8. Quick utilities

**Done** (one commit per row; external-monitor brightness skipped). Binds in HYPRLAND.md §9.

| Utility | Status | What it is |
| --- | --- | --- |
| Keep awake (caffeine) | done | Existed (`Idle.inhibited` → an `IdleInhibitor` on the island window, a `>` action). Added: a `coffee` icon in the trailing indicators while on (a click turns it off) and a "Keep awake" quick toggle; the toggles are two rows of four. |
| Power confirm | already done | `PowerSection` and the `>` actions need a second press for reboot, power off and log out. |
| Color picker | done | `Color` service: `hyprpicker -f hex` (Esc does nothing), copied through `Clipboard.copyText`; a message with a swatch and the hex. IPC `color pick`, `pickIn(ms)`, `last`; `>` "Pick a color"; Super+Ctrl+P. |
| Keyboard layout | done | `Keyboard` service: the main keyboard from `hyprctl -j devices`, kept current by the `activelayout` event and re-read after a config reload; a message on switch; a trailing label ("US") only with more than one layout (the user has one, so it's hidden). IPC `keyboard status`. |
| Game mode | done | `GameMode` service: reads animations, blur, shadows and gaps with `hyprctl -j getoption`, saves them and do-not-disturb to `~/.local/state/ezshell/gamemode.json`, turns them off (gaps 0) with `hyprctl eval 'hl.config({…})'` (keywords on a classic config) and DND on; off restores exactly the saved values. Re-applied after a shell restart or a Hyprland config reload while on. A message, a trailing controller icon (click turns it off), a quick toggle. IPC `gamemode on/off/toggle/status`; Super+Ctrl+G. |
| Hide island | done | `Visibility.islandHidden`, IPC `island hide/show/toggle/status`: the resting pill parks off-screen and the reserved space drops to 0; messages, panels and polkit still drop in. `>` "Hide island"; Super+Ctrl+H. |
| Night light schedule | done | `Config.nightLight.schedule` off / fixed (start, end) / sun (sunset to sunrise at the weather location, from `utils/Sun.qml`, no extra network). Applied only when the schedule's own state changes, so a manual toggle holds until the next change; the Timer runs only while a schedule is on and checks at least every 15 minutes (Qt timers don't count suspend). IPC `setSchedule`, `setTimes`; a section in Settings → Appearance. hyprsunset must run for it to tint (HYPRLAND.md §4). |
| External-monitor brightness | skipped | No DDC monitor: no external display is connected, and `ddcutil detect` only finds the internal panel. Revisit with an external monitor. |

## F9. Keybind cheat sheet and updates

- **Cheat sheet:**
  - Data from `hyprctl binds -j`; modmask bits are SHIFT 1, CTRL 4, ALT 8, SUPER 64.
  - Show the bind's description when it has one. First check that the Lua config exposes descriptions.
  - Island section `keybinds`, grouped and searchable; Super+/.
  - Done: Lua binds expose `description` (`hl.bind` options), but none of the user's binds had one yet, so the sheet groups by the description's prefix and lists undescribed binds last with keys only. HYPRLAND.md §10 has the bind and examples. Identical press/release entries are merged.
- **Updates:** skipped for now (user's call, Nov 7 2026).
  - `Updates` service runs `checkupdates` hourly. Exit code 2 means no updates, not an error.
  - Optional AUR count with `paru -Qua`.
  - An Overview card with the count and the list, and an "Update" button that opens a terminal with `paru` and reports progress through F7.
- **Dependencies:** `pacman-contrib`.

## F10. Window switcher

- **Data:** `Quickshell.Hyprland` toplevels, plus a most-recently-used list in `Hypr`, updated on the `activewindow` event.
- **Behaviour:**
  - Super+Tab opens on the previous window. Tab moves forward, Super+Shift+Tab moves back.
  - Releasing Super focuses the selection, through `GlobalShortcut` press/release or a Hyprland release bind.
- **UI:** the island expands to a row of app icons with the focused title below. Live previews with `ScreencopyView` are optional, later.
- **Done:** all windows on regular workspaces (special workspaces left out), most recent first (`Hypr.recent`: `activewindowv2` events, then Hyprland's `focusHistoryID`). Keys are caught by an always-visible item in `ModeLayers`, so a quick Super release isn't lost while the view fades in. Binds in HYPRLAND.md §11. Live previews not done.

## F11. Theme presets and other apps

- Settings presets: corner-radius scale, surface opacity, blur on/off.
- Optional matugen templates for other apps, one at a time and each opt-in: kitty, GTK (adw-gtk3), Qt (qt6ct or Kvantum), hyprlock, Hyprland borders.

## F12. Desktop widgets (optional)

hyprism-style cards (clock, weather, performance, network, storage, sensors) on a Background-layer window. Reuse `SysInfo` and `Weather`; read hwmon sensors with `FileView`. Skip unless wanted; the dashboard already covers most of this.

## Dependencies this roadmap adds (Arch)

| Package | Feature | Notes |
| --- | --- | --- |
| `cliphist`, `wl-clipboard` | F3 | |
| `noto-fonts-emoji` | F4 | already installed; `python-fonttools` only to re-run the generator |
| `grim`, `slurp`, `gpu-screen-recorder` | F6 | all installed |
| `swappy` or `satty` | F6 | optional, for Edit; swappy is installed |
| `hyprpicker` | F8 | installed |
| `ddcutil` | F8 | optional; external brightness skipped (no DDC monitor) |
| `pacman-contrib` | F9 | |

F1 adds none. F5 landed: stop starting `polkit-gnome` (HYPRLAND.md §7).

## Open questions to check on the real machine

- Whether the Arch `quickshell` package includes polkit support (F5).
- Which of the user's password managers set the KDE password-manager hint (F3).
- Noto Color Emoji coverage of the newest emoji (F4).
- Lua-config binds do expose descriptions (`hl.bind` option `description`), checked for F9; the user's binds have none yet.
- Wi‑Fi SSID missing at shell start (DESIGN.md gotchas): a one-time reconnect, or removing the duplicate NetworkManager profile, would show whether it is the cause. Ask first; both touch the user's network.
- A second monitor has never been tested. Check F1 (per-screen wallpaper) and F10 on one when possible.
