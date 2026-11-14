import QtQuick
import qs.config
import qs.theme
import qs.components

// HIG slider: thin track that fills from the leading side, with a thumb.
// Emits `moved` continuously while dragging, for live feedback.
Item {
    id: root

    property real value
    property real from: 0
    property real to: 1
    property real step: 0.05
    property bool disabled

    signal moved(value: real)

    implicitWidth: Tokens.spacing.xxxl * 5
    implicitHeight: Tokens.control.thumb
    opacity: disabled ? Tokens.state.disabled : 1

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: Tokens.control.track
        radius: height / 2
        color: Theme.color.fill

        Rectangle {
            width: thumb.x + thumb.width / 2
            height: parent.height
            radius: height / 2
            color: Theme.accent
        }
    }

    Rectangle {
        id: thumb

        x: area.fraction * (root.width - width)
        anchors.verticalCenter: parent.verticalCenter
        width: Tokens.control.thumb
        height: Tokens.control.thumb
        radius: height / 2
        color: Theme.color.thumb
        border.width: area.activeFocus ? Tokens.state.focusRing : 1
        border.color: area.activeFocus ? Theme.accent : Theme.color.separator
        scale: area.pressed ? 1.15 : 1

        // Follow the pointer exactly while dragging; ease for key, wheel and
        // outside changes.
        Behavior on x {
            enabled: !area.pressed

            Anim {
                style: Tokens.motion.effectsFast
            }
        }

        Behavior on scale {
            Anim {
                style: Tokens.motion.effectsFast
            }
        }
    }

    ValueArea {
        id: area

        value: root.value
        from: root.from
        to: root.to
        step: root.step
        disabled: root.disabled
        inset: thumb.width / 2
        onMoved: value => root.moved(value)
    }
}
