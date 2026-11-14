import QtQuick
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.components

// The wide Control Center slider: the track itself fills, with an icon inside
// and no thumb. At zero nothing is filled and the icon sits on the bare track.
//
//   value, from, to, step   the level; `moved(value)` asks for a change
//   icon        Material Symbols name, drawn at the left of the track
//   size        one of Tokens.size (default large): the track's height
//   iconSize    an icon token, if the size's own icon is not what you want
//   inset       space to the left of the icon
//   tint        fill colour (default the accent)
//   interactive false makes it a display only: the OSD level bar
Item {
    id: root

    property real value
    property real from: 0
    property real to: 1
    property real step: 0.05
    property string icon
    property color tint: Theme.accent
    property bool interactive: true
    // One of Tokens.size: the track's height. Use the same one as a button
    // beside it and they line up.
    property Tokens.ControlSize size: Tokens.size.xl
    // Icon size. Follows `size` unless set.
    property real iconSize: size.icon
    // Space to the left of the icon.
    property real inset: size.padding
    property bool disabled

    signal moved(value: real)

    implicitWidth: Tokens.spacing.xxxl * 6
    implicitHeight: size.height
    opacity: disabled ? Tokens.state.disabled : 1

    ClippingRectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.color.fill

        Rectangle {
            id: fill

            // Nothing at zero, so the icon sits on the bare track. Follows
            // the value smoothly, but exactly while it is being dragged.
            width: area.fraction * parent.width
            height: parent.height
            color: root.tint

            Behavior on width {
                enabled: !area.pressed

                Anim {
                    style: Tokens.motion.effectsFast
                }
            }

            Behavior on color {
                ColorAnim {}
            }
        }
    }

    // The icon is drawn twice: in the label colour on the bare track, and in
    // the colour for the fill over it, cut off where the fill ends.
    Icon {
        anchors.left: parent.left
        anchors.leftMargin: root.inset
        anchors.verticalCenter: parent.verticalCenter
        visible: root.icon.length > 0
        name: root.icon
        size: root.iconSize
    }

    Item {
        width: fill.width
        height: parent.height
        clip: true

        Icon {
            anchors.left: parent.left
            anchors.leftMargin: root.inset
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon.length > 0
            name: root.icon
            size: root.iconSize
            color: Theme.color.onAccent
        }
    }

    ValueArea {
        id: area

        value: root.value
        from: root.from
        to: root.to
        step: root.step
        disabled: root.disabled || !root.interactive
        onMoved: value => root.moved(value)
    }
}
