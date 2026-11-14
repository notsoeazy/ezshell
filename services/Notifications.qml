pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.config
import qs.services

// The notification server: every app's notifications arrive here. Each is kept
// as a `NotifData` until dismissed, and saved to a file so that they survive a
// restart. A new one is announced as a banner unless Do Not Disturb is on or
// its app has been silenced (urgent ones always get through).
Singleton {
    id: root

    // Newest first.
    property var list: []
    readonly property int count: list.length
    // The apps that have notifications, in the order their groups are shown.
    // An app goes to the front when a notification arrives from it, and only
    // then: dismissing one never reorders the groups, which would make them jump
    // about while you clear them. `order` is that memory of arrivals.
    property var order: []
    readonly property var groupApps: {
        const present = new Set(list.map(n => n.appName));
        const result = order.filter(app => present.has(app));
        for (const item of list) {
            if (!result.includes(item.appName))
                result.push(item.appName);
        }
        return result;
    }
    // The notification being announced, if any.
    property NotifData banner: null
    // Set by the island while the pointer is on the banner: it stays up.
    property bool held
    property int serial

    function isSilenced(appName: string): bool {
        return ShellState.silencedApps.includes(appName);
    }

    function toggleSilenced(appName: string): void {
        const apps = ShellState.silencedApps.filter(name => name !== appName);
        if (apps.length === ShellState.silencedApps.length)
            apps.push(appName);
        ShellState.silencedApps = apps;
    }

    function dismiss(item: NotifData): void {
        if (!item)
            return;

        if (item.source)
            item.source.dismiss();
        else
            remove(item);
    }

    function clear(): void {
        for (const item of [...list])
            dismiss(item);
    }

    // Dismiss everything from one app.
    function clearApp(appName: string): void {
        for (const item of list.filter(n => n.appName === appName))
            dismiss(item);
    }

    // Press one of the app's buttons. Only possible while the app is still
    // connected; the notification goes afterwards unless the app keeps it.
    function invoke(item: NotifData, identifier: string): void {
        const action = Array.from(item?.source?.actions ?? []).find(a => a.identifier === identifier);
        if (!action)
            return;

        action.invoke();
        if (!item.source.resident)
            dismiss(item);
    }

    // The app's desktop entry, if it has one that can be started.
    function entryFor(item: NotifData): var {
        return item ? Apps.entryFor(item.desktopEntry || item.appName, item.appName) : null;
    }

    function openApp(item: NotifData): void {
        entryFor(item)?.execute();
    }

    // "now", "5m", "2h", "3d". Reads the clock, so text bound to it stays
    // current.
    function age(item: NotifData): string {
        if (!item)
            return "";

        const minutes = Math.floor((Time.now.getTime() - item.time) / 60000);
        if (minutes < 1)
            return "now";
        if (minutes < 60)
            return `${minutes}m`;
        if (minutes < 1440)
            return `${Math.floor(minutes / 60)}h`;
        return `${Math.floor(minutes / 1440)}d`;
    }

    // A picture for a notification: the image it carries, else its app's icon.
    // Empty if neither can be found.
    function pictureFor(notification: Notification): string {
        if (notification.image.length > 0)
            return notification.image;
        return iconFor(notification);
    }

    function iconFor(notification: Notification): string {
        const named = Quickshell.iconPath(notification.appIcon, true);
        if (named.length > 0)
            return named;

        const entry = DesktopEntries.heuristicLookup(notification.desktopEntry || notification.appName);
        return Quickshell.iconPath(entry?.icon ?? "", true);
    }

    function remove(item: NotifData): void {
        if (banner === item)
            banner = null;
        list = list.filter(n => n !== item);
        save();
    }

    function add(notification: Notification): void {
        const item = factory.createObject(root, {
            uid: `${Date.now()}-${serial++}`,
            appName: notification.appName,
            desktopEntry: notification.desktopEntry,
            summary: notification.summary,
            body: notification.body,
            picture: pictureFor(notification),
            urgency: notification.urgency,
            time: Date.now(),
            actions: Array.from(notification.actions).map(a => ({
                        identifier: a.identifier,
                        text: a.text
                    })),
            source: notification
        });
        // Whoever closes it (us, the app, a timeout), it leaves the list.
        notification.closed.connect(() => root.remove(item));

        list = [item, ...list].slice(0, Config.notifications.keep);
        order = [item.appName, ...order.filter(app => app !== item.appName)];
        save();

        // Urgent notifications get through Do Not Disturb and silenced apps.
        const critical = item.urgency === NotificationUrgency.Critical;
        if (critical || (!ShellState.doNotDisturb && !isSilenced(item.appName))) {
            banner = item;
            hide.restart();
        }
    }

    // What is written to the file: what the app sent, less what cannot outlive
    // it (an image the server holds in memory is replaced by the app's icon).
    function serialize(item: NotifData): var {
        const transient = item.picture.startsWith("image://qsimage");
        return {
            uid: item.uid,
            appName: item.appName,
            desktopEntry: item.desktopEntry,
            summary: item.summary,
            body: item.body,
            picture: transient ? (item.source ? iconFor(item.source) : "") : item.picture,
            urgency: item.urgency,
            time: item.time
        };
    }

    function save(): void {
        saveTimer.restart();
    }

    function restore(): void {
        const items = adapter.items ?? [];
        list = items.map(saved => factory.createObject(root, {
                uid: saved.uid,
                appName: saved.appName,
                desktopEntry: saved.desktopEntry ?? "",
                summary: saved.summary,
                body: saved.body ?? "",
                picture: saved.picture ?? "",
                urgency: saved.urgency ?? NotificationUrgency.Normal,
                time: saved.time
            })).slice(0, Config.notifications.keep);
        // Newest first, so the newest app's group comes first.
        order = [...new Set(list.map(n => n.appName))];
    }

    onHeldChanged: {
        if (!held && banner !== null)
            hide.restart();
    }

    Component {
        id: factory

        NotifData {}
    }

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        bodySupported: true
        // Bodies are shown as plain text.
        bodyMarkupSupported: false
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;
            root.add(notification);
        }
    }

    Timer {
        id: hide

        interval: Config.notifications.bannerTimeout
        onTriggered: {
            if (!root.held)
                root.banner = null;
        }
    }

    // Saving waits a moment, so a burst of changes is written once.
    Timer {
        id: saveTimer

        interval: 400
        onTriggered: {
            adapter.items = root.list.map(root.serialize);
            store.writeAdapter();
        }
    }

    FileView {
        id: store

        path: `${Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`}/ezshell/notifications.json`
        printErrors: false

        Component.onCompleted: {
            waitForJob();
            root.restore();
        }

        JsonAdapter {
            id: adapter

            property var items: []
        }
    }
}
