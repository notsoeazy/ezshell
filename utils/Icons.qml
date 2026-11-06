pragma Singleton

import Quickshell

// Pure name helpers shared by modules. A QML singleton because qs.<dir> modules don't export .js files.
Singleton {
    function volume(level: real, muted: bool): string {
        if (muted || level <= 0)
            return "volume_off";
        if (level < 1 / 3)
            return "volume_mute";
        return level < 2 / 3 ? "volume_down" : "volume_up";
    }

    function brightness(level: real): string {
        if (level < 1 / 3)
            return "brightness_low";
        return level < 2 / 3 ? "brightness_medium" : "brightness_high";
    }

    function battery(level: real, charging: bool, low: bool, full: bool): string {
        if (charging)
            return "battery_charging_full";
        if (low)
            return "battery_alert";
        if (full)
            return "battery_full";
        // Material Symbols has battery_0_bar to battery_6_bar.
        return `battery_${Math.round(level * 6)}_bar`;
    }

    function wifi(enabled: bool, connected: bool, strength: real): string {
        if (!enabled)
            return "wifi_off";
        if (!connected)
            return "signal_wifi_0_bar";
        if (strength < 0.25)
            return "network_wifi_1_bar";
        if (strength < 0.5)
            return "network_wifi_2_bar";
        return strength < 0.75 ? "network_wifi_3_bar" : "signal_wifi_4_bar";
    }

    function bluetooth(enabled: bool, connected: bool): string {
        if (!enabled)
            return "bluetooth_disabled";
        return connected ? "bluetooth_connected" : "bluetooth";
    }

    // BlueZ reports freedesktop icon names ("audio-headset"); map the common ones to Material Symbols.
    function btDevice(icon: string): string {
        if (icon.startsWith("audio"))
            return "headphones";
        if (icon === "input-mouse")
            return "mouse";
        if (icon === "input-keyboard")
            return "keyboard";
        if (icon === "input-gaming")
            return "sports_esports";
        return icon === "phone" ? "smartphone" : "bluetooth";
    }

    // WMO weather codes (as Open-Meteo reports them) to Material Symbols.
    function weather(code: int, isDay: bool): string {
        if (code === 0)
            return isDay ? "clear_day" : "clear_night";
        if (code <= 2)
            return isDay ? "partly_cloudy_day" : "partly_cloudy_night";
        if (code === 3)
            return "cloud";
        if (code <= 48)
            return "foggy";
        if (code <= 67 || (code >= 80 && code <= 82))
            return "rainy";
        if (code <= 77 || code === 85 || code === 86)
            return "weather_snowy";
        return "thunderstorm";
    }
}
