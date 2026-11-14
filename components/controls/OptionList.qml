pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.components
import qs.components.containers

// A short list of choices, one of them ticked (HIG menu with a selection).
// Shows the `current` index it is given and emits `selected`; the owner
// applies it.
//
//   options   a list of { title, subtitle, icon }
//   current   index of the choice in use
Surface {
    id: root

    required property list<var> options
    property int current

    signal selected(index: int)

    implicitWidth: rows.implicitWidth
    implicitHeight: rows.implicitHeight
    color: Theme.color.fillTertiary

    ColumnLayout {
        id: rows

        anchors.fill: parent
        spacing: 0

        Repeater {
            model: root.options

            ListRow {
                id: row

                required property var modelData
                required property int index

                Layout.fillWidth: true
                title: modelData.title
                subtitle: modelData.subtitle ?? ""
                icon: modelData.icon ?? ""
                separator: index < root.options.length - 1
                onActivated: root.selected(index)

                Icon {
                    name: "check"
                    color: Theme.accent
                    opacity: root.current === row.index ? 1 : 0

                    Behavior on opacity {
                        Anim {
                            style: Tokens.motion.effectsFast
                        }
                    }
                }
            }
        }
    }
}
