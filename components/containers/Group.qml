import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components

// HIG grouped box: a titled, rounded group of rows, as in a settings form.
// Put ListRows inside; give the last one `separator: false`.
//
//   title   optional heading above the group
//   note    optional explanation under it
ColumnLayout {
    id: root

    property string title
    property string note
    default property alias content: rows.data

    spacing: Tokens.spacing.xs

    Label {
        Layout.leftMargin: Tokens.spacing.md
        visible: root.title.length > 0
        text: root.title
        fontSize: Tokens.fontSize.sm
        level: Label.Secondary
    }

    Surface {
        Layout.fillWidth: true
        implicitHeight: rows.implicitHeight

        ColumnLayout {
            id: rows

            anchors.fill: parent
            spacing: 0
        }
    }

    Label {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.spacing.md
        Layout.rightMargin: Tokens.spacing.md
        visible: root.note.length > 0
        text: root.note
        fontSize: Tokens.fontSize.sm
        level: Label.Tertiary
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
    }
}
