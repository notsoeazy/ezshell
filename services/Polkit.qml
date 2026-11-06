pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Polkit

// ezshell's polkit authentication agent: password prompts for pkexec and GUI admin actions show in the
// island. Polkit allows one agent per session, so while another one runs (polkit-gnome from Hyprland's
// execs) registration fails, Quickshell logs why, and that agent keeps answering.
// The response (password) is passed straight to polkit: never stored, logged or exposed over IPC.
Singleton {
    id: root

    readonly property bool registered: agent.isRegistered
    // The request on screen. Quickshell 0.3.1 doesn't queue: its agent pops the active request off its queue,
    // so a second request replaces the open one and the first is never answered (its pkexec hangs). The
    // replaced request is still a live object, so it's kept here and shown again once the newer one ends:
    // newest first, and nothing is dropped. Rare race: if a kept request ends on its own (polkit timeout)
    // while a newer one shows, Quickshell's cleanup removes the newer one.
    readonly property AuthFlow flow: internal.current
    readonly property bool active: root.flow !== null && !root.flow.isCompleted
    // idle, prompt (waiting for a response), checking (submitted, polkit hasn't answered) or failed (wrong
    // response; polkit starts a new attempt by itself, so the prompt stays and the next submit retries).
    readonly property string state: root.active ? root.phase() : "idle"
    readonly property string message: root.flow?.message ?? ""
    readonly property string actionId: root.flow?.actionId ?? ""
    readonly property string iconName: root.flow?.iconName ?? ""
    readonly property var identities: root.flow?.identities ?? []
    readonly property var selectedIdentity: root.flow?.selectedIdentity ?? null
    readonly property string inputPrompt: root.flow?.inputPrompt ?? ""
    readonly property bool responseVisible: root.flow?.responseVisible ?? false
    readonly property string supplementaryMessage: root.flow?.supplementaryMessage ?? ""
    readonly property bool supplementaryIsError: root.flow?.supplementaryIsError ?? false

    function phase(): string {
        return internal.checking ? "checking" : internal.failed ? "failed" : "prompt";
    }

    function submit(response: string): void {
        if (!root.active || internal.checking)
            return;
        internal.checking = true;
        internal.failed = false;
        root.flow.submit(response);
    }

    function cancel(): void {
        root.flow?.cancelAuthenticationRequest();
    }

    // Which user authenticates, when polkit offers more than one (an admin group).
    function selectIdentity(identity: var): void {
        if (root.active)
            root.flow.selectedIdentity = identity;
    }

    function status(): string {
        if (!root.registered)
            return "not registered (is another polkit agent running?)";
        return root.active ? `${root.state}: ${root.actionId}: ${root.message}` : "idle";
    }

    // Shows the agent's request, or else the most recent kept one that's still open.
    function advance(): void {
        const next = agent.flow && !agent.flow.isCompleted ? agent.flow : null;
        const kept = internal.kept.filter(f => f && !f.isCompleted && f !== next);
        internal.current = next ?? kept[kept.length - 1] ?? null;
        internal.kept = kept.filter(f => f !== internal.current);
        internal.checking = false;
        internal.failed = false;
    }

    QtObject {
        id: internal

        property AuthFlow current: null
        // Requests replaced by a newer one while still open (see flow).
        property var kept: []
        property bool checking: false
        property bool failed: false
    }

    PolkitAgent {
        id: agent

        onFlowChanged: {
            if (internal.current && internal.current !== agent.flow && !internal.current.isCompleted)
                internal.kept = [...internal.kept, internal.current];
            root.advance();
        }
    }

    Connections {
        function onIsCompletedChanged(): void {
            if (root.flow?.isCompleted)
                root.advance();
        }

        function onAuthenticationFailed(): void {
            internal.checking = false;
            internal.failed = true;
        }

        function onAuthenticationSucceeded(): void {
            internal.checking = false;
            internal.failed = false;
        }

        function onAuthenticationRequestCancelled(): void {
            internal.checking = false;
            internal.failed = false;
        }

        target: root.flow
    }

    // Status and cancel only. There is deliberately no submit: a password must never travel over IPC.
    IpcHandler {
        function status(): string {
            return root.status();
        }

        function cancel(): void {
            root.cancel();
        }

        target: "polkit"
    }
}
