# 04 · Settings, background and later features

## Settings window

A normal floating toplevel window (`FloatingWindow`), not part of the island.

- Opened from the gear button on the control panel (which closes the island),
  the launcher (`> settings`), or IPC (`settings open <section>`).
- Created when opened and destroyed when closed; it costs nothing while closed.
- Layout follows macOS System Settings: a sidebar of sections, and a page of
  grouped rows.
- Every control reads from and writes to `Config` (or `ShellState`). There is no
  "apply" step; changes take effect at once and are written to the file.
- Text fields write when Return is pressed or the field is left, not on every
  keystroke.

Sections, clustered in the sidebar as connections, the system, the shell,
and about:

| Section | Contents |
| --- | --- |
| Network | Wi-Fi on or off; the network in use, with Disconnect; known networks (Join, Forget); other networks (Join, asking for a password in the row); the wired port; interface, IP address, router and DNS |
| Bluetooth | On or off, discoverable; paired devices (Connect or Disconnect, Forget); nearby devices (Pair) |
| Sound | Output and input: volume, mute and which device; volume and mute for each application playing sound |
| Display | Brightness; Night Light and its colour temperature; Keep awake; each monitor's mode (read only) |
| Notifications | Do Not Disturb, how long a banner stays, lines of text; the on-screen display and its timings |
| Lock Screen | When to lock, turn the screens off and suspend; lock before sleep; lock when the system asks |
| Capture | What a screenshot does, its editor and folder; the recording mode, microphone, frame rate and folder |
| Appearance | Dark mode, accent colour (when the wallpaper's colours are off), colours from the wallpaper and their style, which other programs to colour, the screen border's thickness and corner rounding, reduce motion, animation length |
| Island | Show the island, monitor, the space kept clear below it, clock format, workspace dots, whether the island shrinks to the clock and after how long, timings, which events show status |
| Wallpaper | Draw the wallpaper, current wallpaper with a button to the selector, folder |
| Launcher | The three mode prefixes, result limit |
| About | Where the settings and saved state live, the icon font, and whether each optional tool is installed |

The control panel's pages are for quick changes; these sections are the full
versions and use the same services. Settings rows are explicit: a device or
network row has buttons (Join, Forget, Pair) instead of acting on a click.
`LevelRow` (a slider row) and `ValueRow` (a name and its value) in
`modules/settings/` are shared by the pages.

Monitor resolution and scale are shown but not changed here; they belong to
the Hyprland config.

Adding a section is one page file under `modules/settings/pages/`, one entry in
`Settings.qml`, and its name in `SettingsState.sections`.

## Background

The shell draws the wallpaper itself, in a `Background`-layer window per screen.

Reasons: no wallpaper daemon is installed today (Caelestia draws its own), and
owning the surface makes the wallpaper selector's live preview a crossfade
between two images rather than a round trip through an external tool.

- Current wallpaper path is persisted in state.
- Changing wallpaper crossfades.
- A `preview` source overrides the committed one while the selector is open.

## Lock screen

**Decided: ezshell has its own, minimal, in the style of macOS: the wallpaper
and a clock.** Built on Quickshell's `WlSessionLock` (the secure
ext-session-lock protocol) with PAM for authentication.

Built in phase 13.

- Lock from the session view, the launcher (`> lock`), or
  `qs -p . ipc call session lock`. `session.lockCommand` in the config runs
  another locker instead, when set.
- Content: the wallpaper, dimmed; the date and a large clock; and a password
  field that appears on the first key press or click. Typing goes to the
  field from the start. Escape clears and hides it.
- Wrong password: the field shakes and clears, with a line saying why under
  it. No other UI.
- **Signature transition**: on locking, the island's clock appears to grow and
  travel to its lock-screen position; on unlocking it travels back and shrinks
  into the island, and the lock ends when it arrives.
- The password is checked by PAM with the shell's own service file
  (`assets/pam.d/ezshell`: `pam_unix` plus `pam_faillock`, so failed attempts
  count as they do at login).
- The lock survives a reload of the shell.

How the transition works, since it constrains the design: lock surfaces are
separate from the island's window, and an item cannot move between surfaces. The
lock surface therefore draws its own clock, starting at exactly the island
clock's screen position and size, and animates it into place while the rest
of the lock screen fades in. Both are the same component (`components/Clock`);
the lock screen's is set in the `clock` type style and scaled down to the
island's size at the start, so one number (`progress`, 0 to 1) drives its size
and position. The island's own clock is covered by the lock surface, so it
needs no hiding.

On the island's monitor the clock travels; other monitors simply fade to the
lock screen.

Security rules: the lock is engaged through the protocol before any animation is
shown, input is only ever handled by the lock surface, and a crash of the shell
must leave the session locked (this is what `WlSessionLock` provides; do not
replace it with an ordinary overlay window). Only a correct password ends the
lock: the `Lock` service has no unlock function and there is no IPC for it.
If the shell dies while locked, Hyprland keeps the screen locked; start the
shell again from a TTY and lock once more to get a password field back
(`misc:allow_session_lock_restore` must be on).

Not done: locking by itself when idle, on suspend, or when logind asks
(`loginctl lock-session`).

## Later features

Screen capture, special workspaces, theming from the wallpaper, global
shortcuts and locking when idle were built in phase 14; see
[10-phase-14.md](10-phase-14.md). Still open:

- **Activities.** A recording shows on the island through its own widget.
  Media and recording could share one notion of a long-running thing that adds
  an element to the state views; timers and downloads could follow.
- **Audio.** Moving an application to another output, from the Sound section.
- **Capture.** Pausing a recording; a list of past recordings.
- **Theming.** More built-in templates (Qt, btop, Discord and the rest of
  what Caelestia covers); they work today as user templates.
