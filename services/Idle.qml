pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services

// What happens when the computer is left alone or put to sleep: lock, screens
// off, suspend. Keep Awake (an idle inhibitor) holds all three back.
Scope {
    id: root

    // Set between the system announcing sleep and waking up again.
    property bool sleeping

    IdleMonitor {
        enabled: Config.idle.lockAfter > 0
        timeout: Config.idle.lockAfter
        onIsIdleChanged: {
            if (isIdle)
                Session.lock();
        }
    }

    IdleMonitor {
        enabled: Config.idle.screenOffAfter > 0
        timeout: Config.idle.screenOffAfter
        onIsIdleChanged: Hypr.setScreens(!isIdle)
    }

    IdleMonitor {
        enabled: Config.idle.suspendAfter > 0
        timeout: Config.idle.suspendAfter
        onIsIdleChanged: {
            if (isIdle)
                Session.suspend();
        }
    }

    // Listens to the login manager: it says when the computer is about to
    // sleep, and when something asks for the session to be locked.
    Process {
        running: Config.idle.lockBeforeSleep || Config.idle.lockOnRequest
        // setpriv ends it when the shell goes, however the shell goes.
        command: ["setpriv", "--pdeathsig", "TERM", "stdbuf", "-oL", "dbus-monitor", "--system", "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'", "type='signal',interface='org.freedesktop.login1.Session',member='Lock'"]

        stdout: SplitParser {
            // The sleep signal's value is on the line after it.
            property bool expectingSleep

            onRead: line => {
                if (line.includes("member=Lock")) {
                    if (Config.idle.lockOnRequest)
                        Lock.lock();
                } else if (line.includes("member=PrepareForSleep")) {
                    expectingSleep = true;
                } else if (expectingSleep) {
                    expectingSleep = false;
                    root.sleeping = line.includes("true");
                    if (root.sleeping && Config.idle.lockBeforeSleep)
                        Session.lock();
                }
            }
        }
    }

    // Holds sleep back just long enough for the lock screen to be up, so the
    // desktop is never seen on waking.
    Process {
        running: Config.idle.lockBeforeSleep && !grace.done
        command: ["setpriv", "--pdeathsig", "TERM", "systemd-inhibit", "--what=sleep", "--mode=delay", "--who=ezshell", "--why=Lock the screen before sleep", "sleep", "infinity"]
    }

    Timer {
        id: grace

        // True once the lock has had its time; sleep may go ahead.
        property bool done

        interval: Config.idle.sleepGrace
        running: root.sleeping
        onTriggered: done = true
    }

    Connections {
        function onSleepingChanged(): void {
            if (!root.sleeping)
                grace.done = false;
        }

        target: root
    }
}
