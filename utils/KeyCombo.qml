pragma Singleton

import Quickshell

// Hyprland bind → readable key combo ("Super + Shift + Q"). Pure functions for the Keybinds service. Not
// named "Keys": that is QtQuick's Keys attached property, which shadows a singleton of the same name.
Singleton {
    id: root

    // Hyprland's modmask bits, in display order.
    readonly property var modifiers: [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]]
    readonly property var names: ({
            "xf86monbrightnessup": "Brightness Up",
            "xf86monbrightnessdown": "Brightness Down",
            "mouse:272": "Left click",
            "mouse:273": "Right click",
            "mouse:274": "Middle click",
            "mouse_down": "Scroll down",
            "mouse_up": "Scroll up",
            "return": "Enter",
            "escape": "Esc",
            "space": "Space",
            "tab": "Tab",
            "period": ".",
            "comma": ",",
            "slash": "/",
            "backslash": "\\",
            "minus": "-",
            "equal": "=",
            "grave": "`",
            "print": "Print",
            "delete": "Delete",
            "page_up": "Page Up",
            "page_down": "Page Down",
            "caps_lock": "Caps Lock",
            "num_lock": "Num Lock",
            "up": "↑",
            "down": "↓",
            "left": "←",
            "right": "→"
        })

    // "XF86AudioRaiseVolume" → "Audio Raise Volume"; known names from the table; single letters in caps.
    function key(name: string, keycode: int): string {
        if (name === "")
            return `Code ${keycode}`;
        const known = root.names[name.toLowerCase()];
        if (known !== undefined)
            return known;
        if (name.startsWith("XF86"))
            return name.slice(4).replace(/([a-z])([A-Z])/g, "$1 $2");
        return name.length === 1 ? name.toUpperCase() : name.charAt(0).toUpperCase() + name.slice(1);
    }

    // A bare modifier key (SUPER_L with the Super bit) shows once: "Super", not "Super + Super_L".
    function combo(modmask: int, name: string, keycode: int): string {
        const mods = root.modifiers.filter(m => modmask & m[0]).map(m => m[1]);
        const bare = name.toLowerCase().replace(/_[lr]$/, "");
        if (mods.some(m => m.toLowerCase() === bare))
            return mods.join(" + ");
        return [...mods, root.key(name, keycode)].join(" + ");
    }

    // "Media: Play or pause" → ["Media", "Play or pause"]; no prefix → ["", description].
    function split(description: string): list<string> {
        const colon = description.indexOf(":");
        if (colon <= 0)
            return ["", description];
        return [description.slice(0, colon).trim(), description.slice(colon + 1).trim()];
    }
}
