import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.state
import qs.themes

// Password sub-page, pushed by WifiSection when connect() fails for missing secrets. The text lives
// only in this field: it is never logged, never sent through IPC or argv, and goes away with this
// page (back, collapse, section change). It is also cleared after a failed try.
ColumnLayout {
    id: root

    required property string network
    property bool shown: false
    property bool tried: false

    function submit(): void {
        if (field.text === "")
            return;
        root.tried = true;
        Wifi.connect(root.network, field.text);
    }

    spacing: Appearance.island.expanded.gap
    Component.onCompleted: field.focusInput()
    Component.onDestruction: {
        if (Wifi.needsPassword || Wifi.connecting)
            Wifi.cancel();
    }

    StyledText {
        Layout.fillWidth: true
        text: `Password for ${root.network}`
        elide: Text.ElideRight
        font.weight: Font.Medium
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledTextField {
            id: field

            Layout.fillWidth: true
            password: !root.shown
            placeholder: "Password"
            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
            onAccepted: root.submit()
        }

        StyledButton {
            icon: root.shown ? "visibility_off" : "visibility"
            onClicked: root.shown = !root.shown
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: text !== ""
        text: Wifi.connecting ? "Connecting…" : root.tried && Wifi.needsPassword ? "Wrong password, try again" : ""
        color: Wifi.connecting ? Colors.surfaceVariantFg : Colors.error
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        Item {
            Layout.fillWidth: true
        }

        StyledButton {
            text: "Cancel"
            onClicked: Visibility.back()
        }

        StyledButton {
            text: "Connect"
            filled: true
            enabled: field.text !== "" && !Wifi.connecting
            onClicked: root.submit()
        }
    }

    // A failed try clears the field.
    Connections {
        function onNeedsPasswordChanged(): void {
            if (Wifi.needsPassword && root.tried)
                field.text = "";
        }

        target: Wifi
    }
}
