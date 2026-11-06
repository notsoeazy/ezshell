pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Session actions. Lock is a signal the lockscreen module listens for (this service doesn't know it
// exists); the others are one-off commands, so they use execDetached rather than a Process.
Singleton {
    id: root

    signal lockRequested

    function lock(): void {
        root.lockRequested();
    }

    // Locks first, so the session is never left open after resume.
    function suspend(): void {
        root.lock();
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    function logout(): void {
        Hypr.dispatch("hl.dsp.exit()", "exit");
    }

    function reboot(): void {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function poweroff(): void {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    IpcHandler {
        function lock(): void {
            root.lock();
        }

        function suspend(): void {
            root.suspend();
        }

        function logout(): void {
            root.logout();
        }

        function reboot(): void {
            root.reboot();
        }

        function poweroff(): void {
            root.poweroff();
        }

        target: "session"
    }
}
