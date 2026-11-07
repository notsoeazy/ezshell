pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config

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
    // Text the launcher starts with (a provider prefix), set by openLauncher(); the request count changes on
    // every call, so an open launcher retypes even the same text, or clears for "".
    property string launcherText: ""
    property int launcherRequest: 0
    // The message mode's content (MessageView.qml lists the fields), set by say(). The island shows it for
    // messageDuration ms (0 = until replaced); the request count changes on every say().
    property var message: ({})
    // The resting island parked off-screen and its reserved space released (like under a fullscreen window).
    // Temporary modes, panels and polkit still drop in.
    property bool islandHidden: false
    property int messageDuration: 0
    property int messageRequest: 0
    // Bumped by `osd nowPlaying`: the island shows the now-playing pill.
    property int nowPlayingRequest: 0
    // Something inside the open tab to scroll to ("notifications": Control's notification center); the
    // request count changes on every ask, so asking again while it's open still scrolls.
    property string reveal: ""
    // The screen whose resting island is peeking (hover), "" when none. Not a panel: it never takes the
    // keyboard, and anything else showing wins over it.
    property string peekScreen: ""
    property int revealRequest: 0
    readonly property list<string> tabs: ["control", "media", "system", "weather", "calendar"]
    readonly property list<string> details: ["wifi", "bluetooth", "audio", "power", "display"]
    // Old names that still open their replacement, so existing binds keep working.
    readonly property var aliases: ({
            overview: "control",
            notifications: "control"
        })
    // Sections opened on their own (keybind or IPC), not from the overview: back() collapses them.
    readonly property list<string> standalone: ["wallpapers", "capture", "keybinds"]
    readonly property bool expanded: root.isSection(root.panel)

    function isSection(name: string): bool {
        return root.tabs.includes(name) || root.details.includes(name) || root.standalone.includes(name);
    }

    function canonical(name: string): string {
        return root.aliases[name] ?? name;
    }

    // mon "" = the focused monitor. For "settings", the second argument is the page instead.
    function open(given: string, mon: string): void {
        const name = root.canonical(given);
        if (name === "settings") {
            root.settingsPage = mon !== "" ? mon : root.lastSettingsPage;
            root.lastSettingsPage = root.settingsPage;
            if (root.expanded)
                root.close();
            return;
        }
        root.screen = mon !== "" ? mon : Hyprland.focusedMonitor?.name ?? "";
        root.peekScreen = "";
        root.stack = [];
        root.openedByPointer = false;
        root.panel = name;
        root.reveal = given === "notifications" ? "notifications" : "";
        root.revealRequest++;
    }

    function openByPointer(name: string, mon: string): void {
        root.open(name, mon);
        root.openedByPointer = true;
    }

    // Collapses only if that exact section is open (and not a sub-page of it); otherwise switches to it.
    function toggle(given: string): void {
        const name = root.canonical(given);
        if (name === "settings")
            root.settingsPage = root.settingsPage !== "" ? "" : root.lastSettingsPage;
        else if (root.panel === name && root.stack.length === 0)
            root.close();
        else
            root.open(given, "");
    }

    // The old notifications sub-page is now Control's notification center.
    function push(page: string): void {
        if (page === "notifications")
            root.open("notifications", root.screen);
        else
            root.stack = [...root.stack, page];
    }

    // Sub-page → detail section → Control → collapsed. Tabs and standalone sections collapse.
    function back(): void {
        if (root.stack.length > 0)
            root.stack = root.stack.slice(0, -1);
        else if (root.details.includes(root.panel))
            root.panel = "control";
        else
            root.close();
    }

    function close(): void {
        root.panel = "";
        root.stack = [];
        root.openedByPointer = false;
        root.launcherText = "";
    }

    function say(message: var, duration: int): void {
        root.message = message;
        root.messageDuration = duration;
        root.messageRequest++;
    }

    // Opens the launcher with `text` typed, or retypes it if the launcher is already open.
    function openLauncher(text: string): void {
        root.launcherText = text;
        root.open("launcher", "");
        root.launcherRequest++;
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

        // Opens a sub-page of the open section, e.g. `push password` on Wi‑Fi.
        function push(page: string): void {
            root.push(page);
        }

        function close(): void {
            root.close();
        }

        target: "panels"
    }

    IpcHandler {
        // `launcher open ">"` opens straight into the actions; "" is the plain launcher.
        function open(prefix: string): void {
            root.openLauncher(prefix);
        }

        target: "launcher"
    }

    IpcHandler {
        function hide(): void {
            root.islandHidden = true;
        }

        function show(): void {
            root.islandHidden = false;
        }

        function toggle(): void {
            root.islandHidden = !root.islandHidden;
        }

        function status(): string {
            return root.islandHidden ? "hidden" : "shown";
        }

        // "on" peeks on the focused screen, "off" closes it; for testing without a mouse.
        function peek(state: string): void {
            root.peekScreen = state === "on" ? Hyprland.focusedMonitor?.name ?? "" : "";
        }

        target: "island"
    }

    // Short messages in the island, for scripts. icon is a Material Symbols name. Not "show": `qs ipc call osd show`
    // parses as `qs ipc show`.
    IpcHandler {
        function say(icon: string, text: string): void {
            root.say({
                icon: icon,
                text: text
            }, Config.osd.hideDelay);
        }

        function say2(icon: string, text: string, subtitle: string): void {
            root.say({
                icon: icon,
                text: text,
                subtitle: subtitle
            }, Config.osd.hideDelay);
        }

        // The now-playing pill on demand (it shows on its own on a track change).
        function nowPlaying(): void {
            root.nowPlayingRequest++;
        }

        target: "osd"
    }
}
