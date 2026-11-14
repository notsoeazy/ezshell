import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components

// A row of hints about the keys of a view that has a keyboard: what the keys do
// on the left, and Escape on the far right.
//
//   hints        what to list: [{ key: "↵", text: "enter" }, ...]. A hint has a
//                `key` (a key's name or character) or a `symbol` (an icon
//                name), and what it is called as `text`
//   closeLabel   what Escape does ("close", "cancel")
RowLayout {
    id: root

    property var hints: []
    property string closeLabel: "close"

    Layout.leftMargin: Tokens.spacing.md
    Layout.rightMargin: Tokens.spacing.md
    spacing: Tokens.spacing.lg

    component Hint: RowLayout {
        property string symbol
        property string key
        property string text

        spacing: Tokens.spacing.xs

        Icon {
            visible: parent.symbol.length > 0
            name: parent.symbol
            size: Tokens.icon.xs
            level: Icon.Secondary
        }

        Label {
            visible: parent.key.length > 0
            text: parent.key
            fontSize: Tokens.fontSize.sm
            level: Label.Secondary
        }

        Label {
            text: parent.text
            fontSize: Tokens.fontSize.sm
            level: Label.Secondary
        }
    }

    Repeater {
        model: root.hints

        Hint {
            required property var modelData

            symbol: modelData.symbol ?? ""
            key: modelData.key ?? ""
            text: modelData.text
        }
    }

    Item {
        Layout.fillWidth: true
    }

    Hint {
        key: "esc"
        text: root.closeLabel
    }
}
