pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    readonly property bool enabled: Config.nightLight.enabled
    readonly property int temperature: Config.nightLight.temperature

    function set(enabled: bool): void {
        Config.nightLight.enabled = enabled;
    }

    function toggle(): void {
        root.set(!root.enabled);
    }

    // 1000-6500 K: below that hyprsunset is unusable, above it the screen turns blue instead of neutral.
    function setTemperature(kelvin: int): void {
        Config.nightLight.temperature = Math.max(1000, Math.min(6500, kelvin));
    }

    function apply(): void {
        const args = root.enabled ? ["temperature", `${root.temperature}`] : ["identity"];
        hyprctl.exec(["hyprctl", "hyprsunset", ...args]);
    }

    function status(): string {
        return root.enabled ? `on, ${root.temperature} K` : "off";
    }

    // Applies on every change, including hand edits to config.json and the initial load.
    onEnabledChanged: root.apply()
    onTemperatureChanged: root.apply()
    Component.onCompleted: root.apply()

    Process {
        id: hyprctl

        onExited: code => {
            if (code !== 0)
                console.warn(`[nightlight] hyprctl hyprsunset exited with ${code}; is hyprsunset running?`);
        }
    }

    IpcHandler {
        function toggle(): void {
            root.toggle();
        }

        function set(enabled: bool): void {
            root.set(enabled);
        }

        function setTemperature(kelvin: int): void {
            root.setTemperature(kelvin);
        }

        function status(): string {
            return root.status();
        }

        target: "nightlight"
    }
}
