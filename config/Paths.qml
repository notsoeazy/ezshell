pragma Singleton

import Quickshell

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string config: `${Quickshell.env("XDG_CONFIG_HOME") || root.home + "/.config"}/ezshell`
    readonly property string state: `${Quickshell.env("XDG_STATE_HOME") || root.home + "/.local/state"}/ezshell`

    // "~/x" → "$HOME/x"; anything else unchanged.
    function expand(path: string): string {
        return path.startsWith("~/") ? root.home + path.slice(1) : path;
    }
}
