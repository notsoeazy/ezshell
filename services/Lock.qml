pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pam
import qs.config

// Whether the session is locked, and the password check that unlocks it.
// The lock screen itself is in modules/lock. Nothing but a correct password
// ends the lock: there is deliberately no unlock function and no IPC for it.
Singleton {
    id: root

    readonly property bool locked: persist.locked
    // The password was right: the lock screen is animating away, and the
    // lock ends when it has.
    property bool leaving
    readonly property bool checking: pam.active
    // Why the last attempt failed, in words.
    property string message
    // What PAM itself said about the attempt, if anything.
    property string pamNote
    // Held only until PAM asks for it.
    property string pending

    // An attempt failed; `message` says why.
    signal failed

    function lock(): void {
        if (locked)
            return;

        message = "";
        leaving = false;
        persist.locked = true;
    }

    function submit(password: string): void {
        if (!locked || leaving || pam.active || password.length === 0)
            return;

        pamNote = "";
        pending = password;
        if (!pam.start())
            fail("The password could not be checked.");
    }

    function fail(reason: string): void {
        pending = "";
        message = reason;
        failed();
    }

    // Stay locked across a reload of the shell.
    PersistentProperties {
        id: persist

        property bool locked

        reloadableId: "ezshell-lock"
    }

    PamContext {
        id: pam

        config: "ezshell"
        configDirectory: Quickshell.shellPath("assets/pam.d")

        onPamMessage: {
            if (responseRequired) {
                respond(root.pending);
                root.pending = "";
            } else if (messageIsError) {
                root.pamNote = message;
            }
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.pending = "";
                root.message = "";
                root.leaving = true;
            } else if (result === PamResult.MaxTries) {
                root.fail("Too many attempts. Try again later.");
            } else {
                root.fail(root.pamNote.length > 0 ? root.pamNote : "Wrong password.");
            }
        }
        onError: error => root.fail(`The password could not be checked (${PamError.toString(error)}).`)
    }

    // Give the lock screen the length of its leaving animation.
    Timer {
        interval: Tokens.motion.spatialSlow.duration
        running: root.leaving
        onTriggered: {
            persist.locked = false;
            root.leaving = false;
        }
    }
}
