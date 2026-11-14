pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Warms the screen colours, by running hyprsunset while enabled. Whether it
// is on, and how warm, is remembered between runs.
Singleton {
    id: root

    readonly property bool enabled: ShellState.nightLight
    // Kelvin; lower is warmer.
    readonly property int temperature: ShellState.nightLightTemperature
    readonly property int warmest: 2500
    readonly property int coolest: 6500

    function setEnabled(enabled: bool): void {
        ShellState.nightLight = enabled;
    }

    function setTemperature(kelvin: int): void {
        ShellState.nightLightTemperature = Math.max(warmest, Math.min(coolest, Math.round(kelvin / 100) * 100));
        // Tell the running hyprsunset, rather than restarting it.
        if (sunset.running)
            adjust.running = true;
    }

    Process {
        id: sunset

        running: root.enabled
        command: ["setpriv", "--pdeathsig", "TERM", "hyprsunset", "--temperature", `${root.temperature}`]
        onExited: code => {
            if (root.enabled && code !== 0)
                console.warn(`NightLight: hyprsunset exited with code ${code}`);
        }
    }

    Process {
        id: adjust

        command: ["hyprctl", "hyprsunset", "temperature", `${root.temperature}`]
    }
}
