pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// What's open (docs/ISLAND.md, "State and IPC").
// panel: an island section (tabs or detail sections) or the launcher, on `screen` only.
// stack: sub-pages inside the open section, e.g. ["password"]. temporary: short island modes.
// settingsPage: the settings window's page, "" while closed; its own field so the window stays open
// while the island changes.
Singleton {
    id: root

    property string panel: ""
    property list<string> stack: []
    property string screen: ""
    property string temporary: ""
    // Click vs keybind/IPC; the Wi-Fi password page takes Exclusive keyboard focus only for the latter.
    property bool openedByPointer: false
    property string settingsPage: ""
    property string lastSettingsPage: "wifi"
    readonly property list<string> tabs: ["overview", "media", "system", "calendar"]
    readonly property list<string> details: ["wifi", "bluetooth", "audio", "power"]
    // Sections opened on their own (keybind or IPC), not from the overview: back() collapses them.
    readonly property list<string> standalone: ["wallpapers"]
    readonly property bool expanded: root.isSection(root.panel)

    function isSection(name: string): bool {
        return root.tabs.includes(name) || root.details.includes(name) || root.standalone.includes(name);
    }

    // mon "" = the focused monitor. For "settings", the second argument is the page instead.
    function open(name: string, mon: string): void {
        if (name === "settings") {
            root.settingsPage = mon !== "" ? mon : root.lastSettingsPage;
            root.lastSettingsPage = root.settingsPage;
            if (root.expanded)
                root.close();
            return;
        }
        root.screen = mon !== "" ? mon : Hyprland.focusedMonitor?.name ?? "";
        root.stack = [];
        root.openedByPointer = false;
        root.panel = name;
    }

    function openByPointer(name: string, mon: string): void {
        root.open(name, mon);
        root.openedByPointer = true;
    }

    // Collapses only if that exact section is open (and not a sub-page of it); otherwise switches to it.
    function toggle(name: string): void {
        if (name === "settings")
            root.settingsPage = root.settingsPage !== "" ? "" : root.lastSettingsPage;
        else if (root.panel === name && root.stack.length === 0)
            root.close();
        else
            root.open(name, "");
    }

    function push(page: string): void {
        root.stack = [...root.stack, page];
    }

    // Sub-page → detail section → overview → collapsed. Tabs and standalone sections collapse.
    function back(): void {
        if (root.stack.length > 0)
            root.stack = root.stack.slice(0, -1);
        else if (root.details.includes(root.panel))
            root.panel = "overview";
        else
            root.close();
    }

    function close(): void {
        root.panel = "";
        root.stack = [];
        root.openedByPointer = false;
    }

    function closeSettings(): void {
        root.settingsPage = "";
    }

    IpcHandler {
        function open(name: string, arg: string): void {
            root.open(name, arg);
        }

        function toggle(name: string): void {
            root.toggle(name);
        }

        function back(): void {
            root.back();
        }

        // Opens a sub-page of the open section, e.g. `push notifications` on the overview.
        function push(page: string): void {
            root.push(page);
        }

        function close(): void {
            root.close();
        }

        target: "panels"
    }
}
