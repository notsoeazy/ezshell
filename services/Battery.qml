pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.config

Singleton {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool simulated: fake.active
    readonly property bool available: fake.active || (root.device?.isLaptopBattery ?? false)
    // UPower reports 0-100; Quickshell normalises it to 0-1.
    readonly property real level: fake.active ? fake.level : root.device?.percentage ?? 0
    readonly property int state: root.device?.state ?? UPowerDeviceState.Unknown
    readonly property list<int> chargingStates: [UPowerDeviceState.Charging, UPowerDeviceState.PendingCharge]
    readonly property bool charging: fake.active ? fake.charging : root.chargingStates.includes(root.state)
    readonly property bool full: !fake.active && root.state === UPowerDeviceState.FullyCharged
    readonly property bool low: !root.charging && root.level <= Config.battery.lowLevel
    // Seconds until full while charging, until empty otherwise; 0 when UPower doesn't know.
    readonly property real upowerTimeLeft: (root.charging ? root.device?.timeToFull : root.device?.timeToEmpty) ?? 0
    readonly property real timeLeft: fake.active ? 0 : root.upowerTimeLeft
    readonly property string timeLeftText: root.formatTimeLeft(root.timeLeft, root.charging)
    // Power profile names as power-profiles-daemon spells them; index matches the PowerProfile enum.
    readonly property list<string> profiles: ["power-saver", "balanced", "performance"]
    readonly property string profile: root.profiles[PowerProfiles.profile] ?? ""
    readonly property bool hasPerformance: PowerProfiles.hasPerformanceProfile

    // Testing aid: overrides UPower so the low and charging looks can be checked on any battery.
    function simulate(level: real, charging: bool): void {
        fake.level = Math.max(0, Math.min(1, level));
        fake.charging = charging;
        fake.active = true;
    }

    function reset(): void {
        fake.active = false;
    }

    function profileLabel(name: string): string {
        return ({
                "power-saver": "Power saver",
                "balanced": "Balanced",
                "performance": "Performance"
            })[name] ?? "Unavailable";
    }

    function setProfile(name: string): void {
        const index = root.profiles.indexOf(name);
        if (index < 0 || (name === "performance" && !root.hasPerformance))
            console.warn(`[battery] unknown or unavailable power profile ${name}`);
        else
            PowerProfiles.profile = index;
    }

    function formatTimeLeft(seconds: real, charging: bool): string {
        if (seconds <= 0)
            return "";
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.round((seconds % 3600) / 60);
        const time = hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;
        return charging ? `${time} until full` : `${time} left`;
    }

    function status(): string {
        const simulatedState = root.charging ? "Charging" : "Discharging";
        const state = root.simulated ? simulatedState : UPowerDeviceState.toString(root.state);
        const time = root.timeLeftText !== "" ? `, ${root.timeLeftText}` : "";
        return `${Math.round(root.level * 100)}% ${state}${time}${root.simulated ? " (simulated)" : ""}`;
    }

    QtObject {
        id: fake

        property bool active: false
        property real level: 0
        property bool charging: false
    }

    IpcHandler {
        function status(): string {
            return root.status();
        }

        function simulate(level: real, charging: bool): void {
            root.simulate(level, charging);
        }

        function reset(): void {
            root.reset();
        }

        function profile(): string {
            return root.profile;
        }

        function setProfile(name: string): void {
            root.setProfile(name);
        }

        target: "battery"
    }
}
