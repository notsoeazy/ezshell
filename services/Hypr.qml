pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.config

Singleton {
    id: root

    // Hyprland's Lua config takes Lua expressions over IPC instead of classic dispatcher strings.
    readonly property bool usingLua: Hyprland.usingLua
    readonly property string focusedScreen: Hyprland.focusedMonitor?.name ?? ""
    // The focused window's app id ("firefox"), "" when nothing is focused (an empty workspace).
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property string activeAppId: root.activeWindow?.activated ? root.activeWindow.appId : ""
    readonly property int focusedWorkspace: Hyprland.focusedWorkspace?.id ?? 0
    // Screen capture served by Hyprland (portal shares, wf-recorder, OBS via the portal): counted from
    // `screencast` events. Recorders that read the GPU directly (gpu-screen-recorder -w screen) bypass it.
    // Started before the shell? Missed until it stops and starts again.
    readonly property bool screencasting: internal.screencasts > 0
    // After Config.indicators.delay of continuous capture, so a screenshot (a session lasting a few ms)
    // never shows the indicator.
    readonly property bool screenSharing: root.screencasting && shareDelay.passed
    // "monitor", "window" or "region" for the latest session.
    readonly property string screenShareKind: internal.screencastKind
    // slice(8) strips the "special:" prefix.
    readonly property list<int> occupied: root.withWindows().filter(w => w.id > 0).map(w => w.id)
    readonly property list<string> occupiedSpecial: root.withWindows().filter(w => w.id < 0).map(w => w.name.slice(8))

    function withWindows(): list<HyprlandWorkspace> {
        return Hyprland.workspaces.values.filter(w => w.toplevels.values.length > 0);
    }

    function monitor(screenName: string): HyprlandMonitor {
        return Hyprland.monitors.values.find(m => m.name === screenName) ?? null;
    }

    function activeWorkspace(screenName: string): int {
        return root.monitor(screenName)?.activeWorkspace?.id ?? 0;
    }

    function activeSpecial(screenName: string): string {
        return root.monitor(screenName)?.lastIpcObject.specialWorkspace?.name?.slice(8) ?? "";
    }

    // True fullscreen only: Hyprland also reports maximized windows as fullscreen (mode 1).
    function fullscreen(screenName: string): bool {
        const toplevels = root.monitor(screenName)?.activeWorkspace?.toplevels.values ?? [];
        return toplevels.some(t => (t.lastIpcObject?.fullscreen ?? 0) > 1);
    }

    // event data: "1,monitor" when a session starts, "0,monitor" when it stops.
    function onScreencast(data: string): void {
        const [state, kind] = data.split(",");
        internal.screencasts = Math.max(0, internal.screencasts + (state === "1" ? 1 : -1));
        internal.screencastKind = kind ?? "";
    }

    // Testing aid, like `battery simulate`: pretends a screen capture session is running.
    function simulateScreencast(on: bool): void {
        internal.screencasts = on ? 1 : 0;
        internal.screencastKind = on ? "simulated" : "";
    }

    function screencastStatus(): string {
        return root.screenSharing ? `sharing (${root.screenShareKind})` : "not sharing";
    }

    function dispatch(lua: string, classic: string): void {
        Hyprland.dispatch(root.usingLua ? lua : classic);
    }

    // Steps through workspaces 1 to Config.workspaces.shown, stopping at both ends.
    function cycle(screenName: string, step: int): void {
        const current = root.activeWorkspace(screenName);
        const next = Math.max(1, Math.min(Config.workspaces.shown, current + step));
        if (next !== current)
            root.focus(next);
    }

    function focus(id: int): void {
        root.dispatch(`hl.dsp.focus({ workspace = "${id}" })`, `workspace ${id}`);
    }

    // Launches the entry's app on first use, so the workspace never opens empty.
    function toggleSpecial(name: string): void {
        const entry = Config.workspaces.special.find(w => w.name === name);
        const workspace = `special:${name}`;
        if (!root.occupiedSpecial.includes(name) && entry?.exec) {
            // An exec with a workspace rule places the window silently, so open the workspace first.
            root.dispatch(`hl.dsp.focus({ workspace = "${workspace}" })`, `togglespecialworkspace ${name}`);
            const lua = `hl.dsp.exec_cmd(${JSON.stringify(entry.exec)}, { workspace = "${workspace}" })`;
            root.dispatch(lua, `exec [workspace ${workspace}] ${entry.exec}`);
        } else {
            root.dispatch(`hl.dsp.workspace.toggle_special(${JSON.stringify(name)})`, `togglespecialworkspace ${name}`);
        }
    }

    onScreencastingChanged: {
        if (!root.screencasting)
            shareDelay.passed = false;
    }

    Timer {
        id: shareDelay

        property bool passed: false

        interval: Config.indicators.delay
        running: root.screencasting && !shareDelay.passed
        onTriggered: shareDelay.passed = true
    }

    QtObject {
        id: internal

        property int screencasts: 0
        property string screencastKind: ""
    }

    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            // These states only live in lastIpcObject, which events don't update.
            if (event.name === "activespecial")
                Hyprland.refreshMonitors();
            else if (event.name === "fullscreen")
                Hyprland.refreshToplevels();
            else if (event.name === "screencast")
                root.onScreencast(event.data);
        }

        target: Hyprland
    }

    IpcHandler {
        function focus(id: int): void {
            root.focus(id);
        }

        function toggleSpecial(name: string): void {
            root.toggleSpecial(name);
        }

        function cycle(step: int): void {
            root.cycle(Hyprland.focusedMonitor?.name ?? "", step);
        }

        function screencast(): string {
            return root.screencastStatus();
        }

        function simulateScreencast(on: bool): void {
            root.simulateScreencast(on);
        }

        target: "hypr"
    }
}
