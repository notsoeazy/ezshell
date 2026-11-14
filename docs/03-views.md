# 03 · Views

What each view shows and does. Sizes are starting points to be tuned on screen;
the size *contract* is in [02-island.md](02-island.md).

## States

### `idle`

- Clock only (`HH:mm`, format configurable), always in the middle. While the
  screen is being recorded a red dot sits to its left; while there are
  notifications a bell (no count) sits to its right. Both sides are as wide as the wider one, so the clock never moves.
- Smallest shape: a capsule fused to the top edge.
- No interactive elements; the whole shape is a hover and click target.

### `default`

Shown during a pulse.

- Left: the distribution's logo (click it for the launcher), then the
  workspace indicator, then a recording's red dot. The indicator is a rounded
  container with one dot for each workspace of the focused workspace's page
  (`island.workspaces` per page: 1 to 10, then 11 to 20, ...), every slot
  always shown, occupied ones brighter. The focused one is a wider accent pill
  that slides along as the focus moves, so the indicator never changes width.
  In `default` the container is left out (`contained: false`): the dots sit
  straight on the island and the indicator is narrower by the container's side
  padding. The container and the special workspace's pill are the same height
  (`Tokens.control.sm`), so the island does not change height between them.
  Paging itself is done by the Hyprland binds (`SUPER + 1..0` is the nth
  workspace of the page); the page size here must match theirs.
  While a special workspace is showing, a pill with its icon and name covers
  the dots, and the island stays in `default` until it is put away.
- Centre: clock, always in the middle (the two sides are kept equally wide).
- Right: status icons, all at `Tokens.icon.sm` and filled:
  the Do Not Disturb icon (the Material `do_not_disturb_on`, only while it is
  on), the notification count and bell (only when there are notifications), the
  microphone (always: white while on, orange while an application records from
  it, red while muted), volume, Wi-Fi (one icon, no signal bars; crossed out when off, dimmed when
  not connected), battery (only if a battery exists; bars for how full it is, and the font's
  charging icons whenever a charger is plugged in, even at a charge limit).
- Same height as `idle`, wider.
- The element that caused the pulse may be emphasised briefly (for example the
  active workspace dot animates). Never show a value here that needs reading;
  that is the OSD's job.

### `hovered`

A richer, taller and wider version of `default`, in the same three columns:

```
 [app icon] VSCodium         21:18          All caught up  🔔
 ● ▬ ● ● ● ● ●            Thu, Nov 4       mic  vol  wifi  battery
 ──────────────────────────────────────────────────────────────
 [art]  Midnight City                          ⏮   ⏯   ⏭
        M83 · Spotify
        1:42 ───●──────────────── 4:03
 ──────────────────────────────────────────────────────────────
 latest two or three notifications              Show all
```

- **Fixed width**, `Tokens.island.sheetWidth` (512, content 480), with room between the
  columns. The island only ever grows taller, when the media or notification
  sections appear. Whatever the text, the width stays: a long track title or
  notification is cut short with an ellipsis (HIG: keep text succinct and
  truncate rather than reflow a constrained layout), it does not widen the island.
- **Left**: the focused app's icon and name ("Desktop" when nothing is
  focused), then the distribution's logo (click it for the launcher), the
  workspace dots without their container (click one to go there), then, while
  recording, a red dot. The name is
  the app's desktop entry name found from the window's class, else the class
  tidied up, else the title. The title itself is not used: apps put their name
  at the end (`Page - Google Chrome`), the front, or nowhere, and Spotify's
  title becomes `Artist - Song`. The icon falls back to a generic one.
- **Middle**: the large clock and the date, in full ("Saturday, November 14") when
  the columns either side leave room for it, else short ("Sat, Nov 14"), which
  is what it falls back to with many workspace dots.
- **Right**: how many notifications there are ("All caught up", "1
  notification", "3 notifications") with a bell; below it the
  status icons, without the notification count and bell, which the line above
  replaces. The Do Not Disturb icon stays in them.
- **Media controls** when a player is active, in a `Card`: art, title, the artist
  and player, a scrubber with the elapsed and total time, and previous,
  play/pause and next as plain filled glyphs (Apple's Now Playing). The scrubber
  is a thick bar with no thumb, draggable where the player can seek. Browser
  video often reports no length, a position past its end, or seeking that does
  nothing, so the progress is only believed when the player supports position
  and length, the length is above zero and the position is within it. Otherwise
  the times are left out and the bar is empty; a player that cannot seek gets a
  bar that only displays.
- **Notifications** below, under a small "Notifications" title so they do not
  read as part of the media, with a "Show all" button on the same line (it
  opens the list). The latest three (two while a track is showing, to keep the
  island short) are plain, ungrouped `NotificationItem` cards, with less padding
  than in the list, like the media one, collapsed: the picture, title with
  how long ago and one line of the body, with a neutral gray chevron (not the accent) that opens it in place.
  Click a card and the notifications list opens scrolled to that notification,
  outlined for a moment; swipe a card to dismiss it. The groups and the
  fuller list are in the notifications sheet. With none, a card says "All caught up!". `island.hoveredNotifications` sets whether the section is `"always"` there (the default), there `"whenAny"` notifications exist (omitted otherwise, like the media), or `"never"`.
- Sections with nothing to show are omitted, and the island sizes to fit.

The app name and the notification line are both `HeaderChip`s: the content
stays flush with the column and only the hover highlight is padded. The app
name does nothing when clicked yet (it will open the window's details); the
notification line opens the list. The three columns share one row gap, so the
two rows line up across them.

Clicks: clock or date → `calendar` sheet; the notification line → `notifications` sheet; a
notification card → the same sheet at that notification; a workspace dot → that workspace; media
controls act directly; anywhere else → control panel.

## Control panel

The hub for everyday functions. Modelled on macOS Control Center.

### Root page

Top to bottom:

- **Header**: the clock with the full date under it on the left; on the right
  the battery with its exact percentage, a Settings button (opens the settings
  window) and a Session button (opens the `session` sheet). The two buttons
  stay disabled until their targets are built.
- **Toggle tiles**, two rows: Wi-Fi and Bluetooth, then Keep awake and Do not
  disturb. Each tile shows an icon, a title and a one-line status.
- **Brightness** slider with a round **Night light** toggle beside it.
- **Volume** slider with a round **Microphone** toggle beside it (lit while the
  microphone is live).
- The sliders are fully rounded and exactly as tall as the round toggles
  beside them; a toggle fills with the accent colour while on.
- **Capture row**: a Screenshot button (the default action), and a Record
  button in two parts: the main part starts recording in the mode shown (and
  is a red Stop with the time while recording), the chevron opens the three
  modes below it.
- **Notifications row**: how many there are, with Clear and a Show all button
  that opens the `notifications` sheet.

The sliders are the wide Control Center style with the icon inside the track.
Right-clicking the Night light toggle opens the night light page, and
right-clicking the Microphone toggle opens the sound page. Both pages are also
reachable over IPC (`controlpanel page nightlight`, `controlpanel page audio`),
which is how the launcher's actions will open them.

### Pages (the "mini controls")

**Recommendation: make this a feature of the control panel, as a navigation
stack.** The control panel has a root page and detail pages. Opening a detail
page pushes it; the island morphs to the page's size and the content slides or
crossfades; a back button or Esc pops. This is how Control Center itself works,
and it needs no new concept: the island already resizes to whatever content is
current.

Tile interaction, matching Control Center:

- Click anywhere on the tile: toggle the feature.
- Click the tile's chevron button: open its page.
- Tiles without a page (Keep awake) have no chevron.
- Round toggles beside the sliders: click to toggle, right-click for the page.

Planned pages:

| Page | Contents |
| --- | --- |
| `wifi` | Enable switch, current network, scanned networks with signal and lock, inline password field, rescan |
| `bluetooth` | Enable switch, paired devices with connect/disconnect and battery, discovered devices, scan |
| `audio` | Output volume and device list, input (microphone) volume and device list. Grows into the later audio mixer |
| `nightlight` | Enable switch, temperature slider |

A page is one file extending `PanelPage` (fixed width, header with back button
and title, content below) and one entry in the `Pages` registry. Adding a page
does not touch the island. Which page shows is `IslandState.panelPage`; Escape
and the back button return to the root page, and Escape again closes.

Each page is also addressable from outside: `controlpanel wifi` over IPC opens
the control panel directly on that page, which is how the launcher's actions and
keybinds reach it.

## Sheets

All sheets close on Esc and outside click, and reopen in a clean state.

### `launcher`

One search field, one result list. The start of the search selects the mode.

| Starts with | Mode | Return does |
| --- | --- | --- |
| anything else | Applications: matched on name, then generic name, then keywords; apps launched more often rank higher among equals, and come first when the search is empty | launch |
| `>` | Actions: open the control panel or one of its pages, open or clear notifications, toggle night light, Do Not Disturb, keep awake, mute, microphone, dark mode | run the action |
| `:` | Clipboard history, text and pictures, from `cliphist` | copy the entry again |
| `.` | Emoji, symbols and Nerd Font glyphs, searched by name and keywords | copy the character |

- Keyboard: Up/Down, or Ctrl+J/K, or Ctrl+N/P to move; Return to run; Escape
  clears the search, then closes.
- The look: a fully rounded search field; the results straight on the island
  with no box around them; each row has its picture on a rounded tile; the
  current row is a pill tinted with the accent (`Tokens.state.current`) that
  glides to the next row, carrying "Enter" at its right with it (the hint is
  drawn inside the pill, not on the rows). Under the list a footer names the keys: navigate, `↵ enter`
  and the mode prefixes on the left, and `esc close` on the far right.
- Every row is `Tokens.control.row` (48) tall whichever mode and however many
  lines of text it has, with its icon, picture or character in a slot of one
  width so the text lines up. The list grows with the results up to six rows,
  then scrolls, so the island breathes as you type and no row is cut off. The
  island is `Tokens.island.sheetWidth` wide, the same as `hovered` and the
  notifications list. A blank clipboard entry reads "(blank)".
- Matching ranks the start of a name above the start of a word, above anywhere
  inside, above the letters merely appearing in order.
- Symbols (`.`) search the name and the extra search words, and the name counts
  for far more: the name itself, then a name that starts with the word, the word
  anywhere in the name, the start of one of its words, inside one, and only then
  the search words. So `wifi` puts the glyphs called wifi before the emoji
  tagged "wifi", and `smile` puts names with the word before tags. Each word of a
  query has to match; a query that appears whole and in order in the name
  ("red heart") ranks higher. Nerd Font glyphs rank behind emoji unless a word
  of the search starts with `nf`. If nothing matches whole, letters spread across
  the name are accepted. Typing more of a query searches only what the shorter
  one found, so it stays fast over 12,000 entries.
- Modes are data. Each is one file extending `LauncherMode` (a prefix, a
  placeholder, an icon, `results(query)` and `activate(result)`) and one entry
  in the `Modes` registry. Actions are one list in `Actions.qml`.
- Prefixes and the result limit are configurable (`launcher` section).
- Open it with `qs -p . ipc call launcher toggle`, or straight into a mode with
  `launcher open ">"`.
- Not built: Tab to complete a prefix, a calculator mode, session and
  wallpaper actions (their targets do not exist yet).

### `wallpaper`

- A horizontal strip of five thumbnails, wide and short, with the file name
  on the left and its position ("1 of 374") on the right under it.
- Left/Right, or a click, moves the selection; the selected wallpaper is
  previewed live on the real background. The selected thumbnail is drawn larger
  (`Tokens.state.chosenScale`, 1.25) and eased there and back with the spatial
  animation, as the strip glides to keep it in the middle.
- There are no buttons: Return sets the wallpaper, and Escape or an outside
  click puts back the one that was set when the sheet opened. A footer names the
  keys, as in the launcher: browse and set on the left, `esc cancel` on the far
  right.
- Pictures come from `wallpaper.directory` (default `~/Pictures/Wallpapers`),
  searched three levels deep for jpg, png and webp.
- The strip draws small copies, not the pictures themselves. Each picture is
  shrunk once with ImageMagick and kept in `~/.cache/ezshell/thumbnails`
  (named by a hash of its path, remade if the picture is newer), so the strip
  opens with every thumbnail already there. Missing thumbnails are made in the
  background at startup, at low priority; until one exists the full picture is
  used. Without ImageMagick the selector still works, only slower.
- It opens on the wallpaper that is set, centred in the strip.
- Preview is cheap because the shell draws its own background
  ([04-settings-and-later.md](04-settings-and-later.md)): previewing only
  changes what is shown, and setting writes it to the saved state.
- Until one is chosen, the first picture found is shown.

### `notifications`

- The full list in a tall sheet (`Tokens.island.sheetWidth`, the same as `hovered` and the launcher), grouped by
  app, that grows with the list and then scrolls. A group goes to the front when
  a notification arrives from its app, and stays where it is otherwise: clearing
  notifications never reorders the groups, and an opened group or row stays open
  while others are dismissed or new ones arrive.
- A group of one is just that notification, as a card. A group of more shares
  one card: a header (the app's name, Clear for its notifications, and a toggle
  with its own icon, `unfold_more`/`unfold_less`, so it is not mistaken for a
  row's chevron), a hairline, the newest under it and, closed, a "Show N more" row (it opens the
  group); open it
  and the rest follow, each row set off by a line. The rows run edge to edge in
  the card so that a row's highlight fills it. There is no count pill.
- Header: a Do Not Disturb toggle and Clear.
- One `NotificationItem` is used everywhere (here, the banner and the `hovered`
  cards), collapsed first, as in Caelestia: the picture (the notification's
  image, else its app's icon), the title with how long ago, one line of the body
  cut off with an ellipsis, and a chevron. The chevron opens it (in the list,
  clicking the card does too; in `hovered`, a click on the card opens the list
  at it instead). Every card has a hover and press highlight that fills its whole
  padded area (`spacing.md` all round), edge to edge: the body wraps (up to `notifications.bodyLines`), the app's name
  joins the title line ("Charlie · Messages · now", left out inside a group,
  whose header names the app), and the app's own buttons and ours appear: Open
  (the app), Copy, Silence (no banners from this app; urgent ones still show)
  and Dismiss. There is no separate close button. Where the view does not
  scroll (the banner and `hovered`), dragging down also opens it and up closes
  it. The list has a fixed width, so opening a long notification wraps its text
  onto more lines and never widens the list.
- **Swipe** a notification sideways to dismiss it: past
  `notifications.dismissThreshold` of its width it slides off, short of that it
  springs back.
- **Kept across a restart.** Notifications are the shell's own `NotifData`
  copies, saved (up to `notifications.keep`) to
  `~/.local/state/ezshell/notifications.json`. After a restart they are back,
  but the app that sent one is no longer connected, so its own buttons are gone;
  the rest still works. A notification the app or a timeout closes is removed.
  An image the server only holds in memory is replaced by the app's icon in the
  saved copy.

### `banner`

Not a sheet: a view the island shows on its own, like the OSD.

- A new notification is shown for five seconds (configurable), and stays while
  the pointer is on it.
- Clicking the island while it shows opens the `notifications` sheet.
- Do Not Disturb stops banners, except for notifications marked critical. The
  notification is still added to the list.
- Where the count shows: a bell with a badge in the status icons (`default` and
  `hovered`), the latest three in `hovered`, and a row on the control panel.

### `calendar`

- Month grid of six weeks across the control panel's width, today in an accent
  circle, days of the neighbouring months faint, weekday names in the secondary
  label colour. The week starts on the day your locale says.
- Previous and next month, and a Today button.
- Opened by clicking the clock in the `hovered` view, from the launcher, or
  over IPC.
- No events or integrations in v1.

### `session`

Its own sheet, so it is clean and focused: nothing but the four actions.

- Lock, Log Out, Restart, Shut Down, as a row of square tiles with labels,
  together as wide as the other sheets.
- Keyboard: Left/Right to move, Return to run, Escape to close. Opens with Lock
  selected, the only one that ends nothing.
- Log Out, Restart and Shut Down ask for confirmation in place: the tile turns
  red and reads "Confirm", and a second press runs it. Moving away cancels.
- Opened from the power button on the control panel, the launcher, or IPC.
- Lock opens the shell's lock screen
  ([04-settings-and-later.md](04-settings-and-later.md)), or runs
  `session.lockCommand` if one is set.

## OSD

**Recommendation: one OSD view with two content kinds, fed by one service.**
Do not build a separate toast system. Level changes and feedback messages need
the same things: come out of the island, show briefly, stay while hovered, show
over fullscreen. Splitting them would duplicate all of that. What differs is the
content, so that is where the split goes.

| Kind | Content | Examples |
| --- | --- | --- |
| `level` | icon inside a horizontal level bar, no number | volume, mic volume, brightness |
| `toast` | icon + short message, optional second line | "Microphone muted", "Screenshot copied", "Do not disturb on" |

Behaviour:

- Appears as an island view (see priority rules in 02), including over
  fullscreen windows.
- Not shown while the control panel is open; the change is already visible
  there.
- A new entry of the same kind and source replaces the current one in place and
  restarts the timer (holding a volume key must not flicker).
- Hides after a timeout (default 1.5 s for `level`, 2.5 s for `toast`), paused
  while the pointer is over it.
- Scrolling over a `level` OSD adjusts that value.
- A toast's icon is `Tokens.icon.sm`, and it has a little more room at the
  sides than other views. Anything can post a toast: services, modules, and external scripts over IPC
  (`toast <icon> <message>`; `osd test` shows a sample). This is the "configurable notification-like"
  channel from the spec, and what screenshots and recording will use later.

Which service events raise an OSD is decided in one place (the OSD service), not
scattered across services.

Built so far: volume and mute, brightness, microphone mute, Do Not Disturb,
Night Light, Keep Awake, and a screenshot or recording being saved.

Each can be turned off in the config, under `osd.show`: `volume`, `brightness`,
`microphone`, `doNotDisturb`, `nightLight`, `keepAwake` and `capture` (all on by
default; `osd.enabled` turns the whole display off). Failures, and anything sent
over IPC (`osd toast`, `osd level`), always show. Night Light and Keep Awake are
also in the control panel, so they are dropped, not held, while a panel or sheet
is open. A settings toggle for each is left for later.
The level bar can be dragged or scrolled to change volume or brightness. A
level shown over IPC (`osd level`) is display only. The icon follows the level:
volume goes mute, down, up (and off when muted), brightness low, medium, high
(`Symbols.level`); the control panel's sliders use the same icons.
