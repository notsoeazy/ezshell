# ezshell — Feature Roadmap

Nov 6, 2026. Phases 1–6 and enhancements E1–E6 in `docs/DESIGN.md` are done. This file lists the **next features in build order**, with the decisions already made for each. Work on one feature at a time, top to bottom, unless the user picks another.

The research behind these choices comes from hyprism (commit a545398), caelestia, end-4 "ii" and the Quickshell 0.3.2 source.

## How to work on a roadmap feature

1. **Read before planning:** this feature's section, `CLAUDE.md`, the relevant parts of `docs/DESIGN.md` and `docs/ISLAND.md`, and the code the feature touches.
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
   - update `CLAUDE.md` if the feature adds a service, a shell-out or a rule;
   - commit.

Test wallpapers live in `~/Pictures/Wallpapers/` (the default `Config.wallpaper.folder`). Use them for every wallpaper and theming test.

## Order and status

| # | Feature | Size | Status |
| --- | --- | --- | --- |
| F0 | Make room: split the files near 250 lines | S | done |
| F1 | Wallpaper selector in the island, native transitions | M | done |
| F2 | Launcher providers: registry, calculator, run command | M | next |
| F3 | Clipboard history (`;`) | M | |
| F4 | Emoji, symbols and kaomoji (`:`) | S | |
| F5 | Polkit agent in the island | M | |
| F6 | Screenshots and screen recording | M | |
| F7 | Tasks IPC and generic OSD | S | |
| F8 | Quick utilities | S each | |
| F9 | Keybind cheat sheet and updates | S | |
| F10 | Window switcher (Super+Tab) | M | |
| F11 | Theme presets and matugen templates for other apps | M | |
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

Today `modules/island/LauncherView.qml` searches apps only, through `Apps.search`. Turn it into one launcher that serves several providers, chosen by the prefix the user types. Visual or modal features (wallpapers, polkit, screenshots) stay out of the launcher.

- **Registry.** Each provider is one file in `modules/island/launcher/`. It declares:
  - `prefix` (`""` for apps);
  - `query(text)`, returning items with `icon`, `title`, `subtitle`, plus an optional image or grid flag;
  - `activate(item, modifier)`.

  Providers call services; any `Process` stays in the service. Adding a provider means one file plus one registry line, and `LauncherView` never changes.

| Prefix | Provider | Service | Feature |
| --- | --- | --- | --- |
| none | apps | `Apps` (existing) | — |
| `=` | calculator; also offered automatically when the text starts with a digit | new `Calc` | F2 |
| `>` | run a shell command, with the last 20 as recents | none: `Quickshell.execDetached(["sh", "-c", text])` | F2 |
| `;` | clipboard history | new `Clipboard` | F3 |
| `:` | emoji, symbols, kaomoji | new `Emoji` | F4 |

- **Calculator:** `Calc` runs `qalc -t <expr>` in one `Process`, debounced about 150 ms. Enter copies the result with `wl-copy`. Never evaluate the input as JavaScript.
- **IPC:** `launcher open <prefix>`, so a keybind opens straight into a mode, e.g. `launcher open ";"`.
- **Dependency:** `libqalculate` (provides `qalc`).
- **Done when:**
  - `=2^10` gives 1024 and `5 km to mi` converts;
  - `>notify-send hi` runs;
  - apps search works exactly as before.

## F3. Clipboard history

- **Recording:**
  - `Clipboard` owns `wl-paste --type text --watch cliphist store` and `wl-paste --type image --watch cliphist store`, plus a third `wl-paste --watch` that only signals a refresh.
  - Lists come from `cliphist list`; also `decode <id>`, `delete` and `wipe`.
- **Privacy:**
  - cliphist already skips copies that password managers mark with `x-kde-passwordManagerHint` (KeePassXC does this).
  - Add an incognito switch that pauses recording.
- **Images:** decode on demand into `$XDG_RUNTIME_DIR/ezshell/clip/<id>.png`, show with `Image { asynchronous: true; sourceSize }`, and delete files that are no longer listed.
- **Launcher provider `;`:** rows show a text preview, or a thumbnail with size and resolution.
  - **Enter** copies (`cliphist decode | wl-copy`).
  - **Alt+Enter** pastes: close the launcher, wait about 120 ms, then run `wtype -M ctrl -k v -m ctrl`.
  - **Delete** removes the entry. "Clear all" asks for confirmation.
- **IPC:** `clipboard copy(id)`, `paste(id)`, `delete(id)`, `wipe`, `incognito(bool)`, `status`. Keybind Super+Shift+V → `launcher open ";"`.
- **Dependencies:** `cliphist`, `wl-clipboard`, `wtype`.
- **Done when:**
  - text and screenshots both appear;
  - a KeePassXC copy doesn't appear;
  - Alt+Enter pastes into a normal app;
  - history survives a shell restart. If the watchers die with the shell, move them to Hyprland `exec-once` and document that in HYPRLAND.md.

## F4. Emoji, symbols and kaomoji

- **Data, committed so the shell works offline:**
  - A one-off generator in `scripts/` turns emojibase `compact.raw.json` into `assets/emoji.tsv` (character, name, tags, group, skin variants).
  - Hand-written `assets/symbols.tsv` (arrows, math, currency, typography) and `assets/kaomoji.tsv`.
- **`Emoji` service:**
  - loads the TSVs once with `FileView` and indexes them;
  - searches by prefix plus fuzzy match over name and tags (reuse `utils/Fuzzy`), ignoring accents;
  - keeps recents and the chosen skin tone in `~/.local/state/ezshell/emoji.json`.
- **Launcher provider `:`:**
  - a grid, with category chips (Recent, Smileys, People, Animals, Food, Travel, Objects, Symbols, Flags, Kaomoji);
  - Enter copies the character;
  - Alt+Enter types it with `wtype` after the launcher closes;
  - right-click shows skin tones.
- **Font:** `Noto Color Emoji`. Hide characters the font can't render.
- **Keybind:** Ctrl+Period → `launcher open ":"`.
- **Dependencies:** `noto-fonts-emoji`, `wtype`.

## F5. Polkit agent in the island

The polkit password prompt appears in the island, replacing hyprpolkitagent or polkit-gnome.

- **First step:** confirm the installed Quickshell is built with polkit support. `PolkitAgent.isRegistered` should be true, with no "failed to register listener" in the log. If it isn't, stop and report.
- **API** (checked in the Quickshell 0.3.2 source, `Quickshell.Services.Polkit`):
  - `PolkitAgent` registers itself on creation. It has `isRegistered`, `flow: AuthFlow` and the signal `authenticationRequestStarted`.
  - `AuthFlow` gives `message`, `actionId`, `iconName`, `identities` and a writable `selectedIdentity`.
  - For input it has `inputPrompt` and `responseVisible`; for progress, `supplementaryMessage` / `supplementaryIsError`, `isCompleted` and `isSuccessful`.
  - Methods: `submit(string)` and `cancelAuthenticationRequest()`.
  - Signals: `authenticationSucceeded`, `authenticationFailed` (a new attempt starts by itself) and `authenticationRequestCancelled`.
  - Requests queue in order.
- **Service:** a `Polkit` singleton with `state: idle | prompt | checking | failed`, force-loaded in `shell.qml`.
- **Island:** temporary mode `polkit`, which outranks everything, including the expanded island and the launcher.
  - While it's showing: the island window is on `Overlay` with `keyboardFocus: Exclusive`.
  - Content: lock icon, message, an identity chooser only when there's more than one identity, a password field, and Cancel / Authenticate buttons.
  - On failure, shake and show `supplementaryMessage`. Esc cancels.
- **Security:**
  - The password field uses `echoMode: TextInput.Password` unless `responseVisible`.
  - Clear it right after `submit()`, on cancel and on success. Never log it.
  - **No IPC `submit`, ever.** IPC is `polkit cancel` and `polkit status` only.
- **Setup in HYPRLAND.md:** run only one agent. `systemctl --user disable --now hyprpolkitagent`, and remove any other agent's autostart.
- **Done when:**
  - `pkexec true` and a GUI action both prompt in the island;
  - a wrong password shakes and lets you retry;
  - Cancel works;
  - the lock screen still appears above the prompt.

## F6. Screenshots and screen recording

- **`Capture` service:** `screenshot(mode)` and `record(mode)`, where mode is `region | window | monitor | full`; plus `stop()` and `status`.
- **Screenshots:**
  - `grim`, with `slurp` for a region; window geometry comes from `Hypr`.
  - Saves to `Config.capture.screenshots` and copies to the clipboard (`wl-copy --type image/png`).
  - Optional "Edit" opens `satty`.
- **Recording:**
  - `wf-recorder`, with an audio toggle (`--audio`), for a region, window or monitor.
  - Saves to `Config.capture.recordings`. The E4 recording indicator already shows while it runs.
- **UI:**
  - Island section `capture`: Screenshot / Record × Region / Window / Screen, plus the audio toggle.
  - When done, a notification with "Open folder" and "Copy path".
  - A native frozen-screen region picker (full-screen Overlay window with `ScreencopyView { live: false }`) can replace `slurp` later.
- **Keybinds:** Super+Shift+S region screenshot, Super+Shift+F monitor screenshot, Super+Shift+R opens the capture section.
- **Dependencies:** `grim`, `slurp`, `wf-recorder`, `satty` (optional).

## F7. Tasks IPC and generic OSD

- **Tasks:** external scripts show progress in the island.
  - IPC: `tasks add(id, title, subtitle)`, `update(id, percent)` (−1 for indeterminate), `finish(id)`, `fail(id, reason)`, `remove(id)`, `list`.
  - Island: a small progress ring in Trailing while a task runs, then a short temporary mode with ✓ or ✗ and the title.
  - Overview: a tasks card.
  - Uses: `paru` updates, backups, long builds.
- **Generic OSD:** `osd show(icon, text)`, so scripts can flash a short message in the island. `icon` is a Material Symbols name.

## F8. Quick utilities

Build them one at a time, committing each.

| Utility | How | Where it shows |
| --- | --- | --- |
| Color picker | `hyprpicker -a -f hex` | temporary mode with swatch + hex; Super+Ctrl+P |
| Caffeine | `IdleInhibitor { window: <island window>; enabled }` | quick toggle + Trailing `coffee` indicator |
| Game mode | `hyprctl eval` to turn off animations, blur and gaps (Lua config); restore on exit; also turns on DND | quick toggle + temporary mode |
| Keyboard layout | `hyprctl -j devices` (main keyboard) and the `activelayout` event | temporary mode on change; Trailing label only with more than one layout |
| Power confirm | reboot, power off and log out need a second press | power section |
| Hide island | IPC `island hide/show/toggle` | keybind (check for clashes) |
| External-monitor brightness | `ddcutil setvcp 10` alongside `brightnessctl` | existing `Brightness` and OSD |
| Night light schedule | fixed hours or sunset/sunrise from Config | settings |

## F9. Keybind cheat sheet and updates

- **Cheat sheet:**
  - Data from `hyprctl binds -j`; modmask bits are SHIFT 1, CTRL 4, ALT 8, SUPER 64.
  - Show the bind's description when it has one. First check that the Lua config exposes descriptions.
  - Island section `keybinds`, grouped and searchable; Super+/.
- **Updates:**
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

## F11. Theme presets and other apps

- Settings presets: corner-radius scale, surface opacity, blur on/off.
- Optional matugen templates for other apps, one at a time and each opt-in: kitty, GTK (adw-gtk3), Qt (qt6ct or Kvantum), hyprlock, Hyprland borders.

## F12. Desktop widgets (optional)

hyprism-style cards (clock, weather, performance, network, storage, sensors) on a Background-layer window. Reuse `SysInfo` and `Weather`; read hwmon sensors with `FileView`. Skip unless wanted; the dashboard already covers most of this.

## Dependencies this roadmap adds (Arch)

| Package | Feature | Notes |
| --- | --- | --- |
| `libqalculate` | F2 | |
| `cliphist`, `wl-clipboard` | F3 | |
| `wtype` | F3, F4 | |
| `noto-fonts-emoji` | F4 | |
| `grim`, `slurp`, `wf-recorder` | F6 | |
| `satty` | F6 | optional |
| `hyprpicker` | F8 | |
| `ddcutil` | F8 | optional |
| `pacman-contrib` | F9 | |

F1 adds none. Disable `hyprpolkitagent` and `polkit-gnome` when F5 lands.

## Open questions to check on the real machine

- Whether the Arch `quickshell` package includes polkit support (F5).
- Which of the user's password managers set the KDE password-manager hint (F3).
- Noto Color Emoji coverage of the newest emoji (F4).
- Whether Lua-config binds expose descriptions (F9).
- A second monitor has never been tested. Check F1 (per-screen wallpaper) and F10 on one when possible.
