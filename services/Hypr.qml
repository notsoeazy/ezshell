pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config
import qs.services

// Hyprland state the shell cares about: workspaces and the focused window.
Singleton {
    id: root

    readonly property int activeWorkspace: Hyprland.focusedWorkspace?.id ?? 1
    // Workspaces are grouped in pages of `island.workspaces`: ids 1 to 10 are
    // the first page, 11 to 20 the second, and so on (as in the Hyprland binds).
    readonly property int pageSize: Math.max(1, Config.island.workspaces)
    readonly property int pageStart: Math.floor((activeWorkspace - 1) / pageSize) * pageSize
    // Ids of the regular workspaces that currently exist (Hyprland only keeps
    // a workspace while it has windows or is showing).
    readonly property list<int> occupied: Hyprland.workspaces.values.filter(w => w.id > 0).map(w => w.id)
    // Hyprland only announces the focused window when focus changes, so until
    // the first change after startup, fall back to the one marked activated.
    readonly property HyprlandToplevel activeWindow: Hyprland.activeToplevel ?? Hyprland.toplevels.values.find(t => t.wayland?.activated) ?? null
    readonly property bool hasActiveWindow: activeWindow !== null
    readonly property string activeTitle: activeWindow?.title ?? ""
    readonly property string activeAppId: activeWindow?.wayland?.appId ?? activeWindow?.lastIpcObject.class ?? ""
    readonly property string activeInitialClass: activeWindow?.lastIpcObject.initialClass ?? ""
    // What the focused window is, as a name for people. The title is no use
    // for this: some apps put their name at its end ("Page - Google Chrome"),
    // some at its front, some nowhere, and it changes with the content. The
    // class is stable, so the name comes from the app's desktop entry, else
    // from tidying the class up ("org.kde.dolphin" -> "Dolphin"), else the
    // title. With no window focused it is "Desktop".
    readonly property var activeEntry: Apps.entryFor(activeAppId, activeInitialClass)
    readonly property string activeAppName: !hasActiveWindow ? "Desktop" : (activeEntry?.name ?? tidyClass(activeAppId)) || activeTitle || "Desktop"
    // The app's icon name or path, empty if unknown.
    readonly property string activeAppIcon: activeEntry?.icon ?? ""

    // Whether a fullscreen window is showing on the focused workspace.
    readonly property bool fullscreen: Hyprland.focusedWorkspace?.hasFullscreen ?? false

    // Special workspaces (scratchpads): the names that exist, without the
    // "special:" in front, the one showing ("" if none), and the last shown.
    readonly property list<string> specials: Hyprland.workspaces.values.filter(w => w.name.startsWith("special:")).map(w => w.name.slice(8))
    property string activeSpecial
    property string lastSpecial

    // Show or hide a special workspace; no name means the one last shown.
    function toggleSpecial(name: string): void {
        const target = name.length > 0 ? name : lastSpecial.length > 0 ? lastSpecial : "special";
        if (Hyprland.usingLua)
            Hyprland.dispatch(`hl.dsp.workspace.toggle_special("${target}")`);
        else
            Hyprland.dispatch(`togglespecialworkspace ${target}`);
    }

    function setActiveSpecial(name: string): void {
        activeSpecial = name.startsWith("special:") ? name.slice(8) : "";
        if (activeSpecial.length > 0)
            lastSpecial = activeSpecial;
    }

    // Windows on a screen's showing workspace, as rectangles in that
    // screen's own coordinates, front to back: floating ones first.
    function windowsOn(screen: ShellScreen): list<var> {
        const monitor = Hyprland.monitorFor(screen);
        if (!monitor)
            return [];

        const special = monitor.lastIpcObject.specialWorkspace;
        const workspace = special?.name ? special.id : monitor.activeWorkspace?.id;
        return Hyprland.toplevels.values.map(t => t.lastIpcObject).filter(w => w?.at && w.size && w.workspace?.id === workspace).sort((a, b) => b.floating - a.floating).map(w => Qt.rect(w.at[0] - screen.x, w.at[1] - screen.y, w.size[0], w.size[1]));
    }

    // Ask Hyprland again where everything is; `windowsOn` reads the answer.
    function refreshWindows(): void {
        Hyprland.refreshMonitors();
        Hyprland.refreshToplevels();
    }

    readonly property string focusedMonitor: Hyprland.focusedMonitor?.name ?? ""

    function monitorScale(screen: ShellScreen): real {
        return Hyprland.monitorFor(screen)?.scale ?? 1;
    }

    // Turn every screen on or off. Hyprland's Lua dispatcher only toggles
    // reliably, so look at the state first.
    function setScreens(on: bool): void {
        if (Hyprland.usingLua)
            Quickshell.execDetached(["sh", "-c", `hyprctl monitors -j | grep -q '"dpmsStatus": ${on ? "false" : "true"}' && hyprctl dispatch 'hl.dsp.dpms({ action = "toggle" })'`]);
        else
            Hyprland.dispatch(`dpms ${on ? "on" : "off"}`);
    }

    readonly property list<HyprlandMonitor> monitors: Hyprland.monitors.values

    // "2560 × 1440, 144 Hz, 1.25×"
    function monitorMode(monitor: HyprlandMonitor): string {
        const rate = monitor.lastIpcObject.refreshRate;
        const parts = [`${monitor.width} × ${monitor.height}`];
        if (rate)
            parts.push(`${Math.round(rate)} Hz`);
        parts.push(`${monitor.scale}×`);
        return parts.join(", ");
    }

    // "org.kde.dolphin" -> "Dolphin", "google-chrome" -> "Google Chrome".
    function tidyClass(appClass: string): string {
        const last = appClass.split(".").pop() ?? "";
        return last.replace(/[-_]+/g, " ").trim().replace(/\b\w/g, letter => letter.toUpperCase());
    }

    function focusWorkspace(id: int): void {
        if (id === activeWorkspace)
            return;

        // Hyprland's Lua config mode takes dispatchers as Lua expressions.
        if (Hyprland.usingLua)
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
        else
            Hyprland.dispatch(`workspace ${id}`);
    }

    // "activespecial" carries "name,monitor"; the name is empty when the
    // special workspace is put away.
    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "activespecial")
                root.setActiveSpecial(event.data.split(",")[0]);
        }

        target: Hyprland
    }

    // One may already be showing when the shell starts.
    Process {
        running: true
        command: ["hyprctl", "monitors", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const showing = JSON.parse(text).map(monitor => monitor.specialWorkspace?.name ?? "").find(name => name.length > 0);
                    root.setActiveSpecial(showing ?? "");
                } catch (error) {}
            }
        }
    }
}
