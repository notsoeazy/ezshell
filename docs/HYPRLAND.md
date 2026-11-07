# Hyprland configuration for ezshell

Changes to make in `~/.config/hypr/` when switching from caelestia to ezshell. None of these have been applied yet; the shell works without them, but some behaviour depends on them (marked **required**).

Your config is Lua (`hyprland.lua` + `hyprland/*.lua`). Classic `hyprland.conf` equivalents are in DESIGN.md "IPC and keybinds".

The examples use `qs -p ~/Projects/personal/shell`. If you later symlink the shell to `~/.config/quickshell/ezshell`, use `qs -c ezshell` instead.

```lua
local qs = "qs -p ~/Projects/personal/shell ipc call "
```

## 1. Layer rule for the island (required)

Turn off Hyprland's own layer animation for the island window. Without it, Hyprland fades the island in after its morph has already run, so over a fullscreen app the OSD and banner drop-in is invisible (ISLAND.md "Motion").

In `hyprland/rules.lua`, next to the caelestia `no_anim` rule:

```lua
hl.layer_rule({ match = { namespace = "^ezshell-island$" }, no_anim = true })
```

To try it for one session without editing the file (lost on the next Hyprland reload):

```sh
hyprctl eval 'hl.layer_rule({ match = { namespace = "^ezshell-island$" }, no_anim = true })'
```

Then restart the shell, because layer rules apply when a window is created.

## 2. Start the shell

In `hyprland/execs.lua`, inside `hl.on("hyprland.start", ...)`, replace the caelestia line:

```lua
hl.exec_cmd("caelestia shell -d")          -- remove
hl.exec_cmd("qs -p ~/Projects/personal/shell")
```

Run only one shell at a time: both would fight over notifications, the tray and the top of the screen.

## 3. Keybinds

In `hyprland/keybinds.lua`, replace the caelestia globals for the same keys. Keep the options your current binds use (`locked`, `repeating`).

```lua
-- Volume, mic, brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(qs .. "audio up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(qs .. "audio down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(qs .. "audio toggleMute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(qs .. "audio toggleMicMute"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(qs .. "brightness up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(qs .. "brightness down"), { locked = true, repeating = true })

-- Media
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(qs .. "players playPause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(qs .. "players playPause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(qs .. "players next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(qs .. "players previous"), { locked = true })

-- Island, launcher, settings, lock
hl.bind("SUPER + A", hl.dsp.exec_cmd(qs .. "panels toggle overview"))
hl.bind("SUPER + W", hl.dsp.exec_cmd(qs .. "panels toggle wifi"))
hl.bind("SUPER + N", hl.dsp.exec_cmd(qs .. "panels open overview ''; " .. qs .. "panels push notifications"))
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd(qs .. "panels toggle launcher"), { release = true })
hl.bind("SUPER + PERIOD", hl.dsp.exec_cmd(qs .. "launcher open ':'"))     -- emoji and symbols (replaces caelestia's)
hl.bind("SUPER + V", hl.dsp.exec_cmd(qs .. "launcher open ';'"))          -- clipboard history (replaces caelestia's)
hl.bind("SUPER + I", hl.dsp.exec_cmd(qs .. "panels toggle settings"))
hl.bind(vars.kbLock, hl.dsp.exec_cmd(qs .. "session lock"))

-- Wallpapers: the island picker, and a random one from the folder
hl.bind(vars.kbShowPanels, hl.dsp.exec_cmd(qs .. "panels toggle wallpapers"))
hl.bind("SUPER + ALT + K", hl.dsp.exec_cmd(qs .. "wallpaper random"))

-- Special workspaces (names from Config.workspaces.special)
hl.bind(vars.kbMusicWs, hl.dsp.exec_cmd(qs .. "hypr toggleSpecial music"))
```

`vars.kbShowPanels` is `SUPER + K` in `variables.lua`, today caelestia's panels bind; ezshell takes it over (rename the variable if you like). Check that `SUPER + ALT + K` is free.

Pick free keys for anything new (`SUPER + A`, `SUPER + W`, `SUPER + N`, `SUPER + I` are suggestions); check them against `variables.lua` first. The caelestia `fn.toggle(...)` special-workspace binds and its screenshot/record binds can stay until you replace those tools.

Super+V is `pkill fuzzel || caelestia clipboard` and Super+Period is `pkill fuzzel || caelestia emoji -p` today (`keybinds.lua:174` and `:176`); replace them with the lines above. The `>` actions have no bind for now (`launcher open '>'`). Keep the two `wl-paste --type text|image --watch cliphist store` lines in `execs.lua`: they record the history the shell shows.

## 4. Night light

ezshell drives hyprsunset; it isn't installed yet.

```sh
sudo pacman -S hyprsunset
```

Then start it with the session, in `execs.lua`:

```lua
hl.exec_cmd("hyprsunset")
```

Until then, the log shows `[nightlight] hyprctl hyprsunset exited with 3; is hyprsunset running?` once per change; it's harmless.

## 5. Special workspaces of kind "app"

ISLAND.md "Special workspaces": an `app` workspace (music/Spotify) shows one floating, centered window at about 70% × 80% of the screen with rounded corners and a dimmed backdrop. That's done with window rules on the workspace, kept in your config rather than generated by the shell. Your `rules.lua` already routes Spotify to `special:music` with `create_tag(music_player_tag, { workspace = "special:music" })`; add float, size, center, rounding and dim rules to that tag. Check the rule names against the Hyprland wiki for your version (0.56, Lua config) before writing them.

## 7. Polkit agent

ezshell is now the polkit agent (password prompts in the island). Polkit allows one agent per session, so polkit-gnome must not start, or ezshell's agent can't register and the log shows "An authentication agent already exists for the given subject".

In `hyprland/execs.lua`, remove this line (line 7 today):

```lua
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
```

To switch over without logging out: stop the running one, then restart the shell so it registers.

```sh
kill $(pgrep -f '^/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1$')
```

To go back, put the line back and run `setsid /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &`. Nothing else starts an agent here: there's no `hyprpolkitagent` and no autostart entry. `polkit-gnome` can stay installed.

## 8. Screenshots and recording (recommended, not applied)

Every capture is an IPC call, so any key can call it. Suggested binds, replacing caelestia's in `keybinds.lua` (lines 142–147 today):

```lua
-- Screenshots: saved to ~/Pictures/Screenshots and copied to the clipboard
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(qs .. "capture screenshot region"))
hl.bind("SUPER + SHIFT + F", hl.dsp.exec_cmd(qs .. "capture screenshot monitor"))
hl.bind("Print", hl.dsp.exec_cmd(qs .. "capture screenshot monitor"), { locked = true })

-- The capture section (cards for every screenshot and recording mode, and the sound switch)
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd(qs .. "panels open capture ''"))

-- Recording: the same key starts and stops (to ~/Videos/Recordings; sound follows the section's switch)
hl.bind("CTRL + ALT + R", hl.dsp.exec_cmd(qs .. "capture toggle monitor"))
hl.bind("SUPER + SHIFT + ALT + R", hl.dsp.exec_cmd(qs .. "capture toggle region"))
```

caelestia's `SUPER + SHIFT + ALT + S` (live region picker) and `SUPER + ALT + R` (record with sound) have no direct replacement: the region screenshot above covers the first, and for the second turn on "Record sound" (`capture setAudio true`) and use the toggle. Other calls: `capture screenshot window|full`, `capture record <mode>`, `capture stop`, `capture status`.

## 9. Quick utilities (recommended, not applied)

Every utility is an IPC call. Suggested binds, checked against `keybinds.lua` and `variables.lua`:

```lua
-- Color picker: click a pixel; the hex is copied and shown in the island
hl.bind("SUPER + CTRL + P", hl.dsp.exec_cmd(qs .. "color pick"))

-- Game mode: animations, blur, shadows and gaps off and do not disturb on; the same key restores them
hl.bind("SUPER + CTRL + G", hl.dsp.exec_cmd(qs .. "gamemode toggle"))
```

## 6. Already in place

- `misc.allow_session_lock_restore = true` (`hyprland/misc.lua`): if the shell dies while locked, restarting it takes the lock back instead of leaving you on Hyprland's red "lockscreen died" screen. Keep it.

## Not needed

- No `layerrule` for blur: the island is opaque black.
- No exclusive-zone rules: the island reserves its own space with a 1px window (`ezshell-island-zone`).
