pragma Singleton

import Quickshell

// Material Symbols by name. The font draws an icon when given its name as
// text, so there is no name-to-glyph table; a wrong name shows its letters.
// This only picks names: from graded sets, and from other systems' words.
Singleton {
    id: root

    // Graded sets, lowest first. The first entry means "nothing".
    readonly property var levels: ({
            "wifi": ["signal_wifi_0_bar", "network_wifi_1_bar", "network_wifi_2_bar", "network_wifi_3_bar", "signal_wifi_4_bar"],
            "speaker": ["volume_mute", "volume_down", "volume_up"],
            // Low, medium and high thirds.
            "brightness": ["brightness_low", "brightness_low", "brightness_medium", "brightness_high"],
            "battery": ["battery_0_bar", "battery_1_bar", "battery_2_bar", "battery_3_bar", "battery_4_bar", "battery_5_bar", "battery_6_bar", "battery_full"]
        })

    // BlueZ's kind of device ("audio-headset", "input-mouse") as an icon.
    readonly property var bluetoothKinds: ({
            "audio-headset": "headphones",
            "audio-headphones": "headphones",
            "audio-card": "speaker",
            "input-mouse": "mouse",
            "input-keyboard": "keyboard",
            "input-gaming": "sports_esports",
            "input-tablet": "tablet",
            "phone": "smartphone",
            "computer": "computer",
            "video-display": "tv",
            "printer": "print",
            "camera-photo": "photo_camera"
        })

    function bluetooth(kind: string): string {
        return bluetoothKinds[kind] ?? "bluetooth";
    }

    // The battery icon for a 0..1 charge: bars for how full it is, or, with a
    // charger plugged in, the font's charging icons (20, 30, 50, 60, 80, 90 and
    // full).
    function battery(level: real, pluggedIn: bool): string {
        if (!pluggedIn)
            return root.level("battery", level);
        const steps = [[0.25, "battery_charging_20"], [0.4, "battery_charging_30"], [0.55, "battery_charging_50"], [0.7, "battery_charging_60"], [0.85, "battery_charging_80"], [0.97, "battery_charging_90"]];
        return steps.find(step => level < step[0])?.[1] ?? "battery_charging_full";
    }

    // Icon name for a 0..1 value in a graded set, e.g. level("wifi", 0.6).
    function level(set: string, value: real): string {
        const options = levels[set];
        if (options === undefined) {
            console.warn(`Symbols: unknown level set "${set}"`);
            return "";
        }
        if (value <= 0)
            return options[0];
        return options[1 + Math.min(options.length - 2, Math.floor(value * (options.length - 1)))];
    }
}
