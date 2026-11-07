# Decision log

The user's calls and the reasons behind them, newest first. Read this before planning a feature, so a settled question isn't asked again or quietly reversed. Add an entry, with the date, whenever the user decides something; if a decision is reversed, add a new entry rather than editing the old one.

## 2026-11-07

- **Window switcher (F10):** lists every window on every regular workspace, most recently used first; special workspaces (music app, scratch) are left out because they have their own toggles. Super+Tab / Super+Shift+Tab, releasing Super focuses. Live previews later, if ever.
- **Updates (F9) skipped:** "not necessary for the shell at this time". The keybind cheat sheet shipped alone.
- **Keybind cheat sheet groups** come from the bind description's prefix ("Media: Play or pause"). The user adds descriptions in their own Hyprland config; the shell never edits it.
- **Hover peek, option A:** the workspaces and status icons stay on the top line and slide out to the pill's edges as it widens; the clock never moves. Option B (dropping them to the second line, as in `r1-hovered.jpg`) was declined.
- **Control tab** is 560 wide, with Volume, Microphone and Brightness as three level chips in one row (from `r1-clicked.jpg`) instead of big sliders.
- **Media tab is an audio mixer** like pavucontrol (the user's Ctrl+Alt+V): player card on top, output/input devices on the left, playback/recording apps on the right.
- **Music equalizer sits on the right** (trailing, next to the clock), balancing the tray on the left.
- **Now-playing pill** is part of the island: island height, its padding, content-fit width, centered. The old thinner pill looked like a separate widget.
- **R1 island redesign:** the bento Overview is replaced by a narrow Control tab (tiles, sliders, media row, notification center); weather and system diagnostics get their own tabs; click opens Control; hover shows a taller peek. No Power tile (power stays on the header button). A Display detail section was added. Committed as one commit, not per step. Spec and record: `docs/ISLAND-R1.md`.
- **External monitor brightness (F8) skipped:** no DDC monitor.
- **Tasks dropped (F7):** the user only wants feedback (screenshot saved, recording finished), not a task list or task ring.
- **Testing never touches real data** (now in AGENTS.md "Testing"), after test notifications and screenshots leaked into the user's real lists.

## 2026-11-06

- **Emoji picker (F4):** a grid, like caelestia's; recents kept; skin tones not a priority (unbound). Super+Period opens it.
- **Clipboard (F3):** the user's workflow is Super+V to pick, then Ctrl+V to paste. No incognito mode, no Alt+Enter, no `wtype` auto-paste.
- **Launcher (F2):** no calculator. Caelestia-style `>` actions instead; destructive actions (log out, reboot, power off) need a second Enter. The launcher lives in `modules/launcher/` (the island was crowded); the island hosts its view.
- **Wallpapers (F1):** the picker sits in the island over the active window, Esc collapses; the folder is scanned recursively. In the island it's one row that slides with the selection centered (arrows, scroll); in the settings app it's the multi-row grid, which is better there.
- **Files may pass 250 lines** when the code is efficient and splitting would only scatter it.
- **One morphing island instead of popups:** clicking expands the island in place; status icons deep-link to their page (Wi‑Fi, Bluetooth, audio, power); Wi‑Fi and Bluetooth pickers live in those pages, not in quick-settings tiles. Same reasoning made the OSD an island mode.
- **Wallpapers are drawn by the shell:** never swww, awww, hyprpaper or imagemagick.
