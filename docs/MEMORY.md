# Working memory

State that a new agent needs and the code doesn't show: open items, what the user has confirmed, what is untested. Keep it current: remove items when they're done, and move settled questions to `docs/DECISIONS.md`.

Last updated 2026-11-07, after F11.

## Where things stand

- Roadmap F0–F11 and R1 are done (`docs/ROADMAP.md`). F12 (desktop widgets) is the only remaining roadmap item and is marked optional.
- The user's real shell runs as `qs -c ezshell`; caelestia's shell also still runs (it owns the notification server and its launcher sits on a bare Super release).
- The user tested and confirmed: F11 theme presets, kitty matugen template, paginated responsive wallpaper grid with disk thumbnail cache, Display settings tab, the window switcher with Super+Tab, the Control tab, the media mixer, the peek, the icon fill fix.

## Open items (ask before acting on any)

- **Test clipboard entries:** two test screenshots leaked into the user's cliphist during F7 tests (ids 3063 and 3064). Delete them only with the user's OK.
- **Wi‑Fi SSID at startup:** see DESIGN.md "gotchas". A reconnect test or removing the duplicate NetworkManager profile is pending; the user deferred it.
- **Spotify album colour:** `ColorQuantizer` can't read web URLs, so the equalizer and now-playing tint fall back to `primary` for Spotify. Fixable by downloading the art to `$XDG_RUNTIME_DIR/ezshell/` first; optional.
- **Second monitor:** never tested (per-screen wallpaper, switcher, peek).

## Untested

- Keybind cheat sheet grouping: none of the user's binds has a `description` yet, so only the "No description" group has been seen.
- Switcher on a very fast Super+Tab tap: the release may come before the island has the keyboard; then it stays open until Enter, a click or Esc.

## User-reported, not yet verified

From the user's private notes (`notes.md`, never committed). Some may already be fixed by R1 and later work; check with the user before working on them.

- The animation when status icons switch isn't good.
- The colours of active icons aren't good.
- A placeholder for music when nothing is playing.
- The weather chip goes out of bounds (it was in the old Overview, which R1 removed; check the Weather tab).
- Freeze the screenshot and recording styles once the user is happy with them.
