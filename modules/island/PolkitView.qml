pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.themes

// Polkit password prompt, the island's top mode. The response lives only in the field: it goes straight to
// Polkit.submit(), and the field is cleared right after, on cancel, for each new request and when the view
// goes away. Nothing here logs it or keeps it.
ColumnLayout {
    id: root

    // The show-password toggle; polkit's responseVisible shows it regardless (a non-secret question).
    property bool reveal: false

    function submit(): void {
        if (field.text === "" || Polkit.state === "checking")
            return;
        Polkit.submit(field.text);
        field.text = "";
    }

    function cancel(): void {
        field.text = "";
        Polkit.cancel();
    }

    // polkit's own message (PAM's "Sorry, try again", a fingerprint hint) wins over ours.
    function statusText(): string {
        if (Polkit.state === "checking")
            return "Checking…";
        if (Polkit.supplementaryMessage !== "")
            return Polkit.supplementaryMessage;
        return Polkit.state === "failed" ? "Wrong password, try again" : "";
    }

    function handleKey(event: KeyEvent): void {
        if (event.key !== Qt.Key_Escape)
            return;
        root.cancel();
        event.accepted = true;
    }

    spacing: Appearance.island.polkit.gap
    Component.onCompleted: field.focusInput()
    Component.onDestruction: field.text = ""

    // A new request (or the next one Polkit kept) starts with an empty, focused field.
    Connections {
        function onFlowChanged(): void {
            field.text = "";
            root.reveal = false;
            field.focusInput();
        }

        function onStateChanged(): void {
            if (Polkit.state === "failed")
                shake.restart();
        }

        target: Polkit
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.island.polkit.gap

        MaterialIcon {
            Layout.alignment: Qt.AlignTop
            text: "lock"
            fill: 1
            size: Appearance.island.polkit.icon
            color: Colors.primary
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                text: "Authentication required"
                font.pixelSize: Appearance.font.size.large
                font.weight: Font.DemiBold
            }

            StyledText {
                Layout.fillWidth: true
                text: Polkit.message
                wrapMode: Text.Wrap
            }

            StyledText {
                Layout.fillWidth: true
                text: Polkit.actionId
                elide: Text.ElideMiddle
                color: Colors.surfaceVariantFg
                font.pixelSize: Appearance.font.size.small
            }
        }
    }

    // Who authenticates, only when polkit offers a choice (members of an admin group).
    Flow {
        Layout.fillWidth: true
        visible: Polkit.identities.length > 1
        spacing: Appearance.spacing.small

        Repeater {
            model: Polkit.identities

            StyledButton {
                required property var modelData

                text: modelData.displayName
                checked: modelData === Polkit.selectedIdentity
                onClicked: Polkit.selectIdentity(modelData)
            }
        }
    }

    // Shakes after a wrong response, like a refused login.
    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal
        transform: Translate {
            id: offset
        }

        StyledTextField {
            id: field

            Layout.fillWidth: true
            password: !root.reveal && !Polkit.responseVisible
            placeholder: Polkit.inputPrompt !== "" ? Polkit.inputPrompt.replace(/:\s*$/, "") : "Password"
            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
            enabled: Polkit.state !== "checking"
            onAccepted: root.submit()
            onKeyPressed: event => root.handleKey(event)
        }

        StyledButton {
            visible: !Polkit.responseVisible
            icon: root.reveal ? "visibility_off" : "visibility"
            onClicked: root.reveal = !root.reveal
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: text !== ""
        text: root.statusText()
        wrapMode: Text.Wrap
        color: Polkit.state === "failed" || Polkit.supplementaryIsError ? Colors.error : Colors.surfaceVariantFg
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        Item {
            Layout.fillWidth: true
        }

        StyledButton {
            text: "Cancel"
            onClicked: root.cancel()
        }

        StyledButton {
            text: "Authenticate"
            filled: true
            enabled: field.text !== "" && Polkit.state !== "checking"
            onClicked: root.submit()
        }
    }

    SequentialAnimation {
        id: shake

        Anim {
            target: offset
            property: "x"
            to: Appearance.island.polkit.shake
            duration: Appearance.anim.scaled(Appearance.anim.shake)
        }

        Anim {
            target: offset
            property: "x"
            to: -Appearance.island.polkit.shake
            duration: Appearance.anim.scaled(2 * Appearance.anim.shake)
        }

        Anim {
            target: offset
            property: "x"
            to: 0
            duration: Appearance.anim.scaled(Appearance.anim.shake)
        }

        ScriptAction {
            script: field.focusInput()
        }
    }
}
