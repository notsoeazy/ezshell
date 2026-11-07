pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.utils

// hyprsunset's color temperature, by hand or on a schedule (Config.nightLight.schedule). The schedule only
// acts when its own on/off state changes, so a manual toggle holds until the next sunset/sunrise or
// start/end time. Its Timer runs only while a schedule is on.
Singleton {
    id: root

    readonly property bool enabled: Config.nightLight.enabled
    readonly property int temperature: Config.nightLight.temperature
    readonly property string schedule: Config.nightLight.schedule
    // The next scheduled change, null while there's none (schedule off, or no location yet).
    readonly property var nextChange: internal.next
    // Longest wait between checks.
    readonly property int maxWait: 15 * 60000

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

    function setSchedule(mode: string): void {
        if (["off", "fixed", "sun"].includes(mode))
            Config.nightLight.schedule = mode;
        else
            console.warn(`[nightlight] unknown schedule ${mode}; use off, fixed or sun`);
    }

    // Local "HH:MM" times for the fixed schedule.
    function setTimes(start: string, end: string): void {
        if (root.minutes(start) < 0 || root.minutes(end) < 0) {
            console.warn(`[nightlight] times must be HH:MM, got ${start} and ${end}`);
            return;
        }
        Config.nightLight.start = start;
        Config.nightLight.end = end;
    }

    // "20:30" → 1230; -1 when not a time.
    function minutes(text: string): int {
        const match = /^(\d{1,2}):(\d{2})$/.exec(text.trim());
        if (!match || Number(match[1]) > 23 || Number(match[2]) > 59)
            return -1;
        return Number(match[1]) * 60 + Number(match[2]);
    }

    function dayAt(day: date, offsetDays: int, minute: int): date {
        const at = new Date(day);
        at.setDate(at.getDate() + offsetDays);
        at.setHours(Math.floor(minute / 60), minute % 60, 0, 0);
        return at;
    }

    // { on, next }: whether `now` is inside the night window, and when that next changes. null when the
    // schedule can't be worked out yet (no location for "sun").
    function plan(now: date): var {
        if (root.schedule === "fixed") {
            const start = root.minutes(Config.nightLight.start);
            const end = root.minutes(Config.nightLight.end);
            if (start < 0 || end < 0 || start === end)
                return null;
            const minute = now.getHours() * 60 + now.getMinutes();
            const on = start < end ? minute >= start && minute < end : minute >= start || minute < end;
            const changes = [];
            for (const day of [0, 1])
                changes.push(root.dayAt(now, day, start), root.dayAt(now, day, end));
            return {
                on: on,
                next: changes.filter(c => c > now).sort((a, b) => a - b)[0]
            };
        }
        if (root.schedule !== "sun" || !Weather.located)
            return null;
        const today = Sun.times(root.dayAt(now, 0, 720), Weather.latitude, Weather.longitude);
        const tomorrow = Sun.times(root.dayAt(now, 1, 720), Weather.latitude, Weather.longitude);
        if (!today.sunrise || !tomorrow.sunrise)
            return null;
        const on = now >= today.sunset || now < today.sunrise;
        const next = now < today.sunrise ? today.sunrise : now < today.sunset ? today.sunset : tomorrow.sunrise;
        return {
            on: on,
            next: next
        };
    }

    // Applies the schedule's state when it changed since the last look, and wakes at the next change or
    // within 15 minutes: Qt timers don't count suspended time, so a laptop that slept past a change
    // catches up on its next check.
    function evaluate(): void {
        if (root.schedule === "off") {
            scheduler.stop();
            internal.last = "";
            internal.next = null;
            return;
        }
        if (root.schedule === "sun" && !Weather.located)
            Weather.refresh();
        const now = new Date();
        const plan = root.plan(now);
        if (!plan) {
            scheduler.stop();
            internal.next = null;
            return;
        }
        const state = plan.on ? "on" : "off";
        if (state !== internal.last) {
            internal.last = state;
            root.set(plan.on);
        }
        internal.next = plan.next;
        scheduler.interval = Math.max(1000, Math.min(plan.next - now + 1000, root.maxWait));
        scheduler.restart();
    }

    function apply(): void {
        if (!daemon.running)
            daemon.running = true;
        const args = root.enabled ? ["temperature", `${root.temperature}`] : ["identity"];
        hyprctl.exec(["hyprctl", "hyprsunset", ...args]);
    }

    function status(): string {
        const state = root.enabled ? `on, ${root.temperature} K` : "off";
        if (root.schedule === "off")
            return state;
        const time = internal.next ? Qt.formatTime(internal.next, "HH:mm") : "";
        const next = time !== "" ? `, next change ${time}` : ", waiting for a location";
        return `${state}; schedule ${root.schedule}${next}`;
    }

    // Applies on every change, including hand edits to config.json and the initial load.
    onEnabledChanged: root.apply()
    onTemperatureChanged: root.apply()
    Component.onCompleted: {
        root.apply();
        root.evaluate();
    }

    QtObject {
        id: internal

        // The scheduled state last applied ("on" / "off"), "" before the first look.
        property string last: ""
        property var next: null
    }

    Timer {
        id: scheduler

        onTriggered: root.evaluate()
    }

    // A new schedule or new times apply at once, overriding a manual toggle.
    Connections {
        function onScheduleChanged(): void {
            internal.last = "";
            root.evaluate();
        }

        function onStartChanged(): void {
            internal.last = "";
            root.evaluate();
        }

        function onEndChanged(): void {
            internal.last = "";
            root.evaluate();
        }

        target: Config.nightLight
    }

    Connections {
        function onLocatedChanged(): void {
            root.evaluate();
        }

        target: Weather
    }

    Process {
        id: daemon

        running: true
        command: ["hyprsunset", "--identity"]
        onStarted: retryTimer.restart()
        onExited: code => {
            if (code === 127)
                console.warn("[nightlight] hyprsunset is not installed");
        }
    }

    Timer {
        id: retryTimer

        interval: 150
        onTriggered: root.apply()
    }

    Process {
        id: hyprctl

        onExited: code => {
            if (code === 3 && !retryTimer.running)
                retryTimer.restart();
            else if (code !== 0 && code !== 3)
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

        // off, fixed or sun.
        function setSchedule(mode: string): void {
            root.setSchedule(mode);
        }

        function setTimes(start: string, end: string): void {
            root.setTimes(start, end);
        }

        function status(): string {
            return root.status();
        }

        target: "nightlight"
    }
}
