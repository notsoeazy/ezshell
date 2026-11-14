pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.components
import qs.services

// The workspaces of the current page, in a rounded container: a dot each,
// with the focused one as a wider accent pill that slides to the next. Click
// a dot to go there. The page is the focused workspace's (1 to 10, 11 to 20,
// ...), so the indicator is always the same width and never pushes the rest
// of the island around. While a special workspace is showing, a pill with its
// icon and name covers the container; click it to put the workspace away.
Item {
    id: root

    readonly property int count: Hypr.pageSize
    readonly property int active: Hypr.activeWorkspace - Hypr.pageStart - 1
    readonly property bool special: Hypr.activeSpecial.length > 0
    // Stays while the pill fades out, so its text does not vanish first.
    property string specialName
    // Draw the rounded container behind the dots. Without it the dots sit
    // straight on the island and the indicator is narrower by the container's
    // side padding; the height is the same either way.
    property bool contained: true

    // The container and the special workspace's pill are the same height, so
    // the island does not change height between them. A dot is inset from the
    // container's edge by as much on the sides as above and below. The focused
    // pill is wider than a dot, and makes room by pushing the later dots along.
    readonly property real barHeight: Tokens.control.sm
    readonly property real dot: Tokens.spacing.sm + Tokens.spacing.xxs
    readonly property real inset: (barHeight - dot) / 2
    readonly property real sideInset: contained ? inset : 0
    readonly property real step: dot + Tokens.spacing.xs
    readonly property real extra: Tokens.spacing.md

    function slotX(index: int): real {
        return index * step + (index > active ? extra : 0);
    }

    function update(): void {
        if (special)
            specialName = Hypr.activeSpecial;
    }

    onSpecialChanged: update()
    Component.onCompleted: update()

    implicitWidth: special ? pill.implicitWidth : track.implicitWidth
    implicitHeight: barHeight

    Behavior on implicitWidth {
        Anim {
            style: Tokens.motion.spatialFast
        }
    }

    Rectangle {
        id: track

        anchors.centerIn: parent
        // Constant while the focus moves: every slot plus the pill's extra.
        implicitWidth: root.count * root.step + root.extra - (root.step - root.dot) + root.sideInset * 2
        implicitHeight: root.barHeight
        radius: height / 2
        color: root.contained ? Theme.color.fillTertiary : Qt.alpha(Theme.color.fillTertiary, 0)
        opacity: root.special ? 0 : 1
        // Out of the way of clicks meant for the pill.
        enabled: !root.special

        Behavior on opacity {
            Anim {
                style: Tokens.motion.effectsFast
            }
        }

        Behavior on color {
            ColorAnim {}
        }

        Item {
            id: slots

            x: root.sideInset
            y: root.inset
            height: root.dot

            Repeater {
                model: root.count

                Rectangle {
                    id: mark

                    required property int index
                    readonly property int workspace: Hypr.pageStart + index + 1
                    readonly property bool occupied: Hypr.occupied.includes(workspace)

                    x: root.slotX(index)
                    width: root.dot
                    height: root.dot
                    radius: height / 2
                    color: occupied ? Theme.color.labelSecondary : Theme.color.labelQuaternary
                    visible: index !== root.active

                    Behavior on x {
                        Anim {
                            style: Tokens.motion.spatialFast
                        }
                    }

                    Behavior on color {
                        ColorAnim {}
                    }
                }
            }

            // The focused workspace.
            Rectangle {
                x: root.active * root.step
                width: root.dot + root.extra
                height: root.dot
                radius: height / 2
                color: Theme.accent
                visible: root.active >= 0 && root.active < root.count

                Behavior on x {
                    Anim {
                        style: Tokens.motion.spatialFast
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: event => {
                // The slot whose middle is closest to the click.
                const at = event.x - slots.x;
                let best = 0;
                for (let i = 1; i < root.count; i++) {
                    if (Math.abs(at - (root.slotX(i) + root.dot / 2)) < Math.abs(at - (root.slotX(best) + root.dot / 2)))
                        best = i;
                }
                Hypr.focusWorkspace(Hypr.pageStart + best + 1);
            }
        }
    }

    Rectangle {
        id: pill

        anchors.fill: parent
        // The icon's drawing has empty space inside its box, so the left
        // padding is smaller and the content looks centred.
        readonly property real leftPadding: Tokens.spacing.md - Tokens.spacing.xxs
        readonly property real rightPadding: Tokens.spacing.md

        implicitWidth: leftPadding + content.implicitWidth + rightPadding
        implicitHeight: root.barHeight
        radius: height / 2
        color: Theme.accentContainer
        opacity: root.special ? 1 : 0
        scale: root.special ? 1 : 0.8
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                style: Tokens.motion.effectsFast
            }
        }

        Behavior on scale {
            Anim {
                style: Tokens.motion.spatialFast
            }
        }

        RowLayout {
            id: content

            anchors.left: parent.left
            anchors.leftMargin: pill.leftPadding
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Icon {
                name: Config.island.specialIcons[root.specialName] ?? "layers"
                size: Tokens.icon.sm
                color: Theme.onAccentContainer
            }

            Label {
                text: root.specialName
                emphasized: true
                color: Theme.onAccentContainer
                fontSize: Tokens.fontSize.md
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Hypr.toggleSpecial(root.specialName)
        }
    }
}
