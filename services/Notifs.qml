pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.config

Singleton {
    id: root

    readonly property list<Notification> list: server.trackedNotifications.values
    readonly property int count: root.list.length
    // The newest notification still open; the banner shows it.
    readonly property Notification latest: internal.latest
    readonly property bool dnd: Config.notifications.dnd

    // Every new notification, DND or not; listeners decide whether to show it.
    signal received(Notification notification)

    function setDnd(enabled: bool): void {
        Config.notifications.dnd = enabled;
    }

    function toggleDnd(): void {
        root.setDnd(!root.dnd);
    }

    function clear(): void {
        [...root.list].forEach(n => n.dismiss());
    }

    function dismiss(notification: Notification): void {
        notification?.dismiss();
    }

    // Runs the "default" action when the app offers one, then closes the notification.
    function activate(notification: Notification): void {
        notification?.actions.find(a => a.identifier === "default")?.invoke();
        notification?.dismiss();
    }

    function status(): string {
        return `${root.count} notifications, dnd ${root.dnd ? "on" : "off"}`;
    }

    function describe(): string {
        return root.list.map(n => `${n.id} [${n.appName}] ${n.summary}: ${n.body}`).join("\n");
    }

    QtObject {
        id: internal

        property Notification latest: null
    }

    NotificationServer {
        id: server

        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: notification => {
            // Untracked notifications are dropped by Quickshell right after this handler.
            notification.tracked = true;
            internal.latest = notification;
            root.received(notification);
        }
    }

    Connections {
        function onClosed(): void {
            internal.latest = null;
        }

        target: internal.latest
    }

    IpcHandler {
        function clear(): void {
            root.clear();
        }

        function toggleDnd(): void {
            root.toggleDnd();
        }

        function setDnd(enabled: bool): void {
            root.setDnd(enabled);
        }

        function status(): string {
            return root.status();
        }

        function list(): string {
            return root.describe();
        }

        target: "notifs"
    }
}
