pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.components

// HIG sidebar: a column of sections to switch between, with the current one
// filled in the accent colour. Shows the `current` index it is given and
// emits `selected`; the owner applies it.
//
//   title     optional heading above the items
//   items     a list of { title, icon }; `gap: true` on an item starts a
//             new cluster, with space above it
//   current   index of the section showing
ColumnLayout {
    id: root

    property string title
    required property list<var> items
    property int current

    signal selected(index: int)

    spacing: Tokens.spacing.xxs

    Label {
        Layout.margins: Tokens.spacing.sm
        visible: root.title.length > 0
        text: root.title
        fontSize: Tokens.fontSize.xl
        emphasized: true
    }

    Repeater {
        model: root.items

        Rectangle {
            id: item

            required property var modelData
            required property int index
            readonly property bool selected: root.current === index
            readonly property color foreground: selected ? Theme.color.onAccent : Theme.color.label

            Layout.fillWidth: true
            Layout.topMargin: modelData.gap ? Tokens.spacing.md : 0
            implicitHeight: Tokens.control.xl
            radius: Tokens.radius.sm
            // Fades to a transparent accent, not to black.
            color: selected ? Theme.accent : Qt.alpha(Theme.accent, 0)

            Behavior on color {
                ColorAnim {}
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.spacing.sm
                anchors.rightMargin: Tokens.spacing.sm
                spacing: Tokens.spacing.sm

                Icon {
                    name: item.modelData.icon
                    size: Tokens.icon.sm
                    filled: item.selected
                    color: item.foreground
                }

                Label {
                    Layout.fillWidth: true
                    text: item.modelData.title
                    color: item.foreground
                }
            }

            Pressable {
                radius: item.radius
                onActivated: root.selected(item.index)
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
