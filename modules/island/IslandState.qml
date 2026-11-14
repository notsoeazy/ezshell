pragma Singleton

import QtQuick
import Quickshell
import qs.config
import qs.services

// Decides which view the island shows.
Singleton {
    id: root

    // The configured monitor, or the first one if it is unset or unplugged.
    readonly property ShellScreen screen: Quickshell.screens.find(s => s.name === Config.island.monitor) ?? Quickshell.screens[0] ?? null

    readonly property list<string> states: ["idle", "default", "hovered", "osd", "banner"]
    property list<string> knownViews

    // The control panel or sheet asked for, or empty.
    property string requested

    // The control panel page showing; empty for its root page.
    property string panelPage
    // What the launcher's search starts with when it opens.
    property string launcherQuery
    // The notification the list should scroll to and highlight, by `uid`, or
    // empty.
    property string focusedNotification
    property bool pointerInside
    property bool hovered
    property bool pulsing
    property bool hoverBlocked

    // Output: first match wins.
    readonly property string current: requested.length > 0 ? requested : Osd.active ? "osd" : Notifications.banner !== null ? "banner" : hovered ? "hovered" : pulsing || Hypr.activeSpecial.length > 0 || !Config.island.idleView ? "default" : "idle"
    readonly property bool inState: requested.length === 0

    // A click on the island itself: the list behind a banner, else the
    // control panel.
    function activate(): void {
        open(current === "banner" ? "notifications" : "controlpanel");
    }

    function open(view: string): void {
        if (!knownViews.includes(view) || states.includes(view)) {
            console.warn(`IslandState: cannot open "${view}"`);
            return;
        }
        requested = view;
    }

    // Open the control panel on one of its pages ("" is the root page).
    function openPanel(page: string): void {
        panelPage = page;
        requested = "controlpanel";
    }

    // Open the notification list at one notification.
    function openNotification(uid: string): void {
        focusedNotification = uid;
        open("notifications");
    }

    // Open the launcher, optionally with the search already started (a
    // mode's prefix, for example).
    function openLauncher(query: string): void {
        launcherQuery = query;
        requested = "launcher";
    }

    // One step back: from a control panel page to its root, else close.
    function back(): void {
        if (requested === "controlpanel" && panelPage.length > 0)
            panelPage = "";
        else
            close();
    }

    function close(): void {
        if (requested.length === 0)
            return;

        requested = "";
        panelPage = "";
        focusedNotification = "";
        hovered = false;
        hoverBlocked = pointerInside;
    }

    function toggle(view: string): void {
        if (requested === view)
            close();
        else
            open(view);
    }

    // Show `default` for a while, in response to an event.
    function pulse(): void {
        pulsing = true;
        pulseTimer.restart();
    }

    onPointerInsideChanged: {
        if (pointerInside) {
            exitTimer.stop();
            if (!hoverBlocked)
                enterTimer.restart();
        } else {
            enterTimer.stop();
            hoverBlocked = false;
            exitTimer.restart();
        }
    }

    Timer {
        id: enterTimer

        interval: Config.island.hoverEnterDelay
        onTriggered: root.hovered = true
    }

    Timer {
        id: exitTimer

        interval: Config.island.hoverExitDelay
        onTriggered: root.hovered = false
    }

    Timer {
        id: pulseTimer

        interval: Config.island.pulseDuration
        onTriggered: root.pulsing = false
    }
}
