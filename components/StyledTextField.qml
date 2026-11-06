import QtQuick
import qs.themes

// Single-line text field. `text` is two-way; owners usually commit on editingFinished.
StyledRect {
    id: root

    property alias text: input.text
    property alias validator: input.validator
    property alias inputMethodHints: input.inputMethodHints
    property string placeholder: ""
    property bool password: false

    signal accepted
    signal editingFinished

    function focusInput(): void {
        input.forceActiveFocus();
    }

    implicitWidth: Appearance.control.fieldWidth
    implicitHeight: Appearance.control.height
    radius: height / 2
    color: Colors.surfaceContainerHigh
    border.width: input.activeFocus ? Appearance.control.borderWidth : 0
    border.color: Colors.primary

    TextInput {
        id: input

        anchors.fill: parent
        anchors.leftMargin: Appearance.spacing.large
        anchors.rightMargin: Appearance.spacing.large
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        color: Colors.surfaceFg
        selectionColor: Colors.primary
        selectedTextColor: Colors.primaryFg
        font.family: Appearance.font.family
        font.pixelSize: Appearance.font.size.normal
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        onAccepted: root.accepted()
        onEditingFinished: root.editingFinished()
    }

    StyledText {
        anchors.fill: input
        verticalAlignment: Text.AlignVCenter
        visible: input.text === ""
        text: root.placeholder
        color: Colors.surfaceVariantFg
    }
}
