pragma Singleton

import Quickshell

// Whether the settings window is open, and on which section. Anything may
// open it: the control panel, the launcher, IPC.
Singleton {
    id: root

    readonly property list<string> sections: ["network", "bluetooth", "sound", "display", "notifications", "lock", "capture", "appearance", "island", "wallpaper", "launcher", "about"]
    property bool visible
    // Opens on Appearance the first time.
    property int section: sections.indexOf("appearance")

    // Open the window; a section name jumps to it, anything else keeps the
    // section last shown.
    function open(name: string): void {
        const index = sections.indexOf(name);
        if (index >= 0)
            section = index;
        visible = true;
    }

    function close(): void {
        visible = false;
    }

    function toggle(): void {
        visible = !visible;
    }
}
