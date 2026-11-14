pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.components

// HIG segmented control: one choice from a few equal-width options. The
// highlight slides to the selected segment.
Rectangle {
    id: root

    required property list<string> segments
    property int current
    property bool disabled
    readonly property real padding: Tokens.spacing.xxs
    readonly property real segmentWidth: segments.length > 0 ? (width - padding * 2) / segments.length : 0

    signal selected(index: int)

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: Tokens.control.md + padding * 2
    radius: Tokens.radius.sm + padding
    color: Theme.color.fill
    opacity: disabled ? Tokens.state.disabled : 1

    Behavior on color {
        ColorAnim {}
    }

    Surface {
        x: root.padding + root.current * root.segmentWidth
        y: root.padding
        width: root.segmentWidth
        height: root.height - root.padding * 2
        radius: Tokens.concentric(root.radius, root.padding)
        color: Theme.color.control
        visible: root.current >= 0 && root.current < root.segments.length

        Behavior on x {
            Anim {
                style: Tokens.motion.spatialFast
            }
        }
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 0
        uniformCellSizes: true

        Repeater {
            model: root.segments

            Item {
                id: segment

                required property string modelData
                required property int index

                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitWidth: label.implicitWidth + Tokens.spacing.md * 2
                implicitHeight: label.implicitHeight

                Label {
                    id: label

                    anchors.centerIn: parent
                    text: segment.modelData
                }

                Pressable {
                    disabled: root.disabled
                    radius: Tokens.concentric(root.radius, root.padding)
                    onActivated: root.selected(segment.index)
                }
            }
        }
    }
}
