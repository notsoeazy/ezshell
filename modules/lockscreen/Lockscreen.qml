pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.services

// Session lock with a PAM password check (assets/pam.d/ezshell). If the shell dies while locked,
// Hyprland keeps the session locked; misc:allow_session_lock_restore lets a restarted shell take over.
Scope {
    id: root

    readonly property bool locked: sessionLock.locked
    property string error: ""
    // Bumped after each failed try, so every screen clears its field.
    property int failures: 0

    function lock(): void {
        root.error = "";
        sessionLock.locked = true;
    }

    function submit(password: string): void {
        if (pam.active || password === "")
            return;
        internal.buffer = password;
        root.error = "";
        pam.start();
    }

    QtObject {
        id: internal

        property string buffer: ""
    }

    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface {
            id: lockSurface

            LockSurface {
                anchors.fill: parent
                screen: lockSurface.screen
                error: root.error
                busy: pam.active
                failures: root.failures
                onSubmitted: password => root.submit(password)
            }
        }
    }

    PamContext {
        id: pam

        config: "ezshell"
        configDirectory: Quickshell.shellPath("assets/pam.d")
        onResponseRequiredChanged: {
            if (!responseRequired)
                return;
            respond(internal.buffer);
            internal.buffer = "";
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                sessionLock.locked = false;
                return;
            }
            root.error = result === PamResult.MaxTries ? "Too many attempts, try again later" : "Wrong password";
            root.failures++;
        }
    }

    Connections {
        function onLockRequested(): void {
            root.lock();
        }

        target: Session
    }

    IpcHandler {
        function lock(): void {
            root.lock();
        }

        function isLocked(): bool {
            return root.locked;
        }

        target: "lock"
    }
}
