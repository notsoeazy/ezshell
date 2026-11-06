pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services

Singleton {
    id: root

    readonly property bool enabled: Config.idle.enabled
    // Keep awake. The island module turns this into a Wayland idle inhibitor on its window.
    readonly property bool inhibited: internal.inhibited

    function setInhibited(inhibited: bool): void {
        internal.inhibited = inhibited;
    }

    function toggleInhibit(): void {
        root.setInhibited(!root.inhibited);
    }

    function status(): string {
        const keepAwake = `keep awake ${root.inhibited ? "on" : "off"}`;
        if (!root.enabled)
            return `idle off, ${keepAwake}`;
        return `lock after ${Config.idle.lockAfter}s, screen off after ${Config.idle.screenOffAfter}s, ${keepAwake}`;
    }

    QtObject {
        id: internal

        property bool inhibited: false
    }

    IdleMonitor {
        enabled: root.enabled
        timeout: Config.idle.lockAfter
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                Session.lock();
        }
    }

    IdleMonitor {
        enabled: root.enabled
        timeout: Config.idle.screenOffAfter
        respectInhibitors: true
        onIsIdleChanged: {
            const action = isIdle ? "disable" : "enable";
            Hypr.dispatch(`hl.dsp.dpms({ action = "${action}" })`, isIdle ? "dpms off" : "dpms on");
        }
    }

    IpcHandler {
        function toggleInhibit(): void {
            root.toggleInhibit();
        }

        function setInhibited(inhibited: bool): void {
            root.setInhibited(inhibited);
        }

        function status(): string {
            return root.status();
        }

        target: "idle"
    }
}
