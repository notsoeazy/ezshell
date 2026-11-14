import QtQuick
import qs.config
import qs.components.controls

// A text field for a setting. It shows `value`, and reports what was typed
// when Return is pressed or the field is left, so a setting is not rewritten
// on every keystroke.
TextField {
    id: root

    required property string value

    signal committed(text: string)

    function commit(): void {
        if (text !== value)
            committed(text);
    }

    implicitWidth: Tokens.spacing.xxxl * 7
    text: value
    onAccepted: commit()
    onEditingChanged: {
        if (!editing)
            commit();
    }
}
