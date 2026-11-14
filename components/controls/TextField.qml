pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.components

// HIG text field. Unlike other controls it owns its text (read or set `text`);
// `secure` hides it behind a reveal toggle, `clearable` adds a clear button.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder
    property string leadingIcon
    property bool secure
    property bool clearable
    // A fully rounded field.
    property bool capsule
    // One of Tokens.size: the field's height.
    property Tokens.ControlSize size: Tokens.size.md
    property bool disabled
    // Whether a secure field is currently showing its text.
    property bool revealed
    property bool cursorOn: true
    readonly property bool editing: input.activeFocus

    signal accepted

    function focusInput(): void {
        input.forceActiveFocus();
    }

    function clear(): void {
        input.clear();
    }

    implicitWidth: Tokens.spacing.xxxl * 6
    implicitHeight: size.height
    radius: capsule ? height / 2 : Math.min(Tokens.radius.sm, height / 2)
    color: Theme.color.fillTertiary
    border.width: editing ? Tokens.state.focusRing : 0
    border.color: Theme.accent
    opacity: disabled ? Tokens.state.disabled : 1

    Behavior on color {
        ColorAnim {}
    }

    Behavior on border.width {
        Anim {
            style: Tokens.motion.effectsFast
        }
    }

    HoverHandler {
        cursorShape: Qt.IBeamCursor
    }

    TapHandler {
        enabled: !root.disabled
        onTapped: root.focusInput()
    }

    Timer {
        running: root.editing
        repeat: true
        interval: Tokens.state.cursorBlink
        onTriggered: root.cursorOn = !root.cursorOn
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Tokens.spacing.sm
        anchors.rightMargin: Tokens.spacing.sm
        spacing: Tokens.spacing.xs

        Icon {
            visible: root.leadingIcon.length > 0
            name: root.leadingIcon
            size: Tokens.icon.sm
            level: Icon.Secondary
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Label {
                anchors.fill: parent
                visible: input.text.length === 0 && input.preeditText.length === 0
                text: root.placeholder
                level: Label.Tertiary
            }

            TextInput {
                id: input

                anchors.fill: parent
                enabled: !root.disabled
                activeFocusOnTab: true
                verticalAlignment: TextInput.AlignVCenter
                selectByMouse: true
                echoMode: root.secure && !root.revealed ? TextInput.Password : TextInput.Normal
                passwordCharacter: "•"
                color: Theme.color.label
                selectionColor: Qt.alpha(Theme.accent, Tokens.state.selection)
                selectedTextColor: Theme.color.label
                font.family: Tokens.font.family
                font.pixelSize: Tokens.fontSize.md
                font.variableAxes: ({
                        "wght": Tokens.fontWeight.regular
                    })

                onAccepted: root.accepted()
                // Keep the cursor solid while typing or moving it.
                onCursorPositionChanged: root.cursorOn = true
                Keys.onEscapePressed: event => {
                    if (root.clearable && text.length > 0)
                        clear();
                    else
                        event.accepted = false;
                }

                cursorDelegate: Rectangle {
                    width: Tokens.state.focusRing
                    color: Theme.accent
                    visible: input.activeFocus && root.cursorOn
                }
            }
        }

        Accessory {
            visible: root.secure
            icon: root.revealed ? "visibility_off" : "visibility"
            onActivated: root.revealed = !root.revealed
        }

        Accessory {
            visible: root.clearable && input.text.length > 0
            icon: "cancel"
            filled: true
            onActivated: {
                root.clear();
                root.focusInput();
            }
        }
    }

    // A small trailing icon that acts as a button.
    component Accessory: Item {
        id: accessory

        required property string icon
        property bool filled

        signal activated

        implicitWidth: Tokens.icon.md
        implicitHeight: Tokens.icon.md

        Icon {
            anchors.centerIn: parent
            name: accessory.icon
            filled: accessory.filled
            size: Tokens.icon.sm
            level: Icon.Secondary
        }

        Pressable {
            disabled: root.disabled
            radius: height / 2
            onActivated: accessory.activated()
        }
    }
}
