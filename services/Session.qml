pragma Singleton

import QtQuick
import Quickshell
import qs.config
import qs.services

// Ending or locking the session.
Singleton {
    function lock(): void {
        if (Config.session.lockCommand.length > 0)
            run(Config.session.lockCommand);
        else
            Lock.lock();
    }

    function logout(): void {
        run(["loginctl", "terminate-session", Quickshell.env("XDG_SESSION_ID")]);
    }

    function suspend(): void {
        run(["systemctl", "suspend"]);
    }

    function reboot(): void {
        run(["systemctl", "reboot"]);
    }

    function poweroff(): void {
        run(["systemctl", "poweroff"]);
    }

    function run(command: list<string>): void {
        Quickshell.execDetached(command);
    }
}
