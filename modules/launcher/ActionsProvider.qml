import QtQuick
import qs.services
import qs.state
import qs.utils

// ">" actions (caelestia style): open island sections and settings pages, flip toggles, session.
// Each action is one push in actionList(). Log out, reboot and power off take a second Enter.
Provider {
    id: root

    // Key of the action waiting for its second Enter, "" when none.
    property string armed: ""

    // An action: key, title, icon, group (the subtitle), run, and for toggles the current state;
    // confirm marks the ones that need the second Enter.
    function actionList(): var {
        const open = (name, title, icon) => ({
                    key: `open-${name}`,
                    title: title,
                    icon: icon,
                    group: "Island",
                    run: () => Visibility.open(name, "")
                });
        const page = (name, title, icon) => ({
                    key: `settings-${name}`,
                    title: `${title} settings`,
                    icon: icon,
                    group: "Settings",
                    run: () => Visibility.open("settings", name)
                });
        // Named after what Enter does, so they don't read like the section of the same name.
        const toggle = (key, title, icon, on, run) => ({
                    key: `toggle-${key}`,
                    title: `Turn ${on ? "off" : "on"} ${title}`,
                    icon: icon,
                    group: on ? "On now" : "Off now",
                    run: run
                });
        const session = (key, title, icon, run, confirm) => ({
                    key: `session-${key}`,
                    title: title,
                    icon: icon,
                    group: "Session",
                    run: run,
                    confirm: confirm
                });
        const list = [open("overview", "Overview", "dashboard"), open("media", "Media", "music_note")];
        list.push(open("system", "System", "monitoring"), open("calendar", "Calendar", "calendar_month"));
        list.push(open("wifi", "Wi‑Fi", "wifi"), open("bluetooth", "Bluetooth", "bluetooth"));
        list.push(open("audio", "Audio", "volume_up"), open("power", "Power", "battery_full"));
        list.push(open("wallpapers", "Wallpapers", "wallpaper"));
        list.push({
            key: "open-notifications",
            title: "Notifications",
            icon: "notifications",
            group: "Island",
            run: () => {
                Visibility.open("overview", "");
                Visibility.push("notifications");
            }
        });
        list.push(page("wifi", "Wi‑Fi", "wifi"), page("bluetooth", "Bluetooth", "bluetooth"));
        list.push(page("audio", "Audio", "volume_up"), page("power", "Power", "battery_full"));
        list.push(page("workspaces", "Workspaces", "grid_view"), page("appearance", "Appearance", "palette"));
        list.push(toggle("wifi", "Wi‑Fi", "wifi", Wifi.enabled, () => Wifi.toggle()));
        list.push(toggle("bluetooth", "Bluetooth", "bluetooth", Bt.enabled, () => Bt.toggle()));
        list.push(toggle("dnd", "do not disturb", "do_not_disturb_on", Notifs.dnd, () => Notifs.toggleDnd()));
        list.push(toggle("nightlight", "night light", "nightlight", NightLight.enabled, () => NightLight.toggle()));
        list.push(toggle("awake", "keep awake", "coffee", Idle.inhibited, () => Idle.toggleInhibit()));
        list.push({
            key: "wallpaper-random",
            title: "Random wallpaper",
            icon: "shuffle",
            group: "Wallpaper",
            run: () => Wallpapers.random()
        });
        list.push(session("lock", "Lock", "lock", () => Session.lock(), false));
        list.push(session("suspend", "Suspend", "bedtime", () => Session.suspend(), false));
        list.push(session("logout", "Log out", "logout", () => Session.logout(), true));
        list.push(session("reboot", "Reboot", "restart_alt", () => Session.reboot(), true));
        list.push(session("poweroff", "Power off", "power_settings_new", () => Session.poweroff(), true));
        return list;
    }

    // All actions in list order while the query is empty; otherwise the matches, best first.
    function matches(query: string): var {
        const all = root.actionList();
        const q = query.trim();
        if (q === "")
            return all;
        // Titles use a non-breaking hyphen (Wi‑Fi); match it as a plain one. Ties keep list order.
        const scored = all.map((a, index) => ({
                    action: a,
                    index: index,
                    score: Fuzzy.score(q.replace("-", "\u2011"), a.title)
                })).filter(m => m.score > 0);
        scored.sort((a, b) => b.score - a.score || a.index - b.index);
        return scored.map(m => m.action);
    }

    function row(action: var): var {
        const armed = action.key === root.armed;
        return Object.assign({}, action, {
            subtitle: armed ? `Press Enter again to ${action.title.toLowerCase()}` : action.group
        });
    }

    prefix: ">"
    name: "actions"
    icon: "bolt"
    emptyText: "No matching actions"
    items: root.current ? root.matches(root.query).map(root.row) : []
    onQueryChanged: root.armed = ""
    onActivated: item => {
        if (item.confirm && root.armed !== item.key) {
            root.armed = item.key;
            return;
        }
        root.armed = "";
        item.run();
        // Sections replace the launcher in the island; everything else closes it.
        if (Visibility.panel === "launcher")
            Visibility.close();
    }
}
