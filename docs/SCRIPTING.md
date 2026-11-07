# Scripting the island

Scripts talk to ezshell over Quickshell's IPC. List every target and function with:

```sh
qs -p ~/Projects/personal/shell ipc show
```

The examples define a short helper first. If the shell later lives in `~/.config/quickshell/ezshell`, use `qs -c ezshell` instead of `qs -p …`.

```sh
ez() { qs -p ~/Projects/personal/shell ipc call "$@"; }
```

## A short message: `osd say` and `osd say2`

`icon` is a Material Symbols name (`check_circle`, `error`, `update`, `backup`, …; see fonts.google.com/icons). The message shows in the island for the OSD hide delay (`osd.hideDelay` in `config.json`).

```sh
ez osd say check_circle "Backup finished"
ez osd say2 update "Updating packages" "paru -Syu"
```

The function is `say`, not `show`: `qs ipc call osd show …` is read as `qs ipc show`.

## Reporting the end of a long command

Wrap the command and say how it ended. For example, a system update with paru:

```sh
#!/bin/sh
# update.sh: run paru -Syu in a terminal and report the result in the island.
ez() { qs -p ~/Projects/personal/shell ipc call "$@"; }

ez osd say2 update "Updating packages" "paru -Syu"
if paru -Syu; then
    ez osd say2 check_circle "Packages updated" "paru -Syu finished"
else
    ez osd say2 error "Update failed" "paru exited with $?"
fi
```

Run it in a terminal (paru asks for confirmation and the sudo password), for example from a keybind: `kitty -e sh ~/bin/update.sh`. The same shape works for backups and builds:

```sh
if rsync -a ~/Documents/ /mnt/backup/Documents/; then
    ez osd say check_circle "Backup finished"
else
    ez osd say2 error "Backup failed" "rsync exited with $?"
fi
```

Messages don't stack: a newer one replaces the one on screen.

## Other useful calls

- `ez capture screenshot region|window|monitor|full`, `ez capture toggle monitor` (recording; see HYPRLAND.md §8)
- `ez launcher open ">"` (actions), `ez launcher open ";"` (clipboard history), `ez launcher open ":"` (emoji)
- `ez panels open overview ""`, `ez panels open wallpapers ""`, `ez panels open capture ""`
