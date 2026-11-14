import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.components

// HIG button. Style sets prominence (use one Filled button per view), role
// marks destructive actions, `size` is one of Tokens.size, and a button with
// no text is a square icon button.
Surface {
    id: root

    enum Style {
        Plain,
        Gray,
        Tinted,
        Filled
    }

    enum Role {
        Normal,
        Destructive
    }

    property string text
    property string icon
    property int style: Button.Gray
    property int role: Button.Normal
    // One of Tokens.size: sets the height, and the default icon size,
    // padding and text.
    property Tokens.ControlSize size: Tokens.size.md
    property bool capsule
    // Draw the icon filled in, for a button that shows an on state.
    property bool iconFilled
    // Icon size. Follows `size` unless set; beside text it stays at the
    // size that suits the text, however tall the button is.
    property real iconSize: iconOnly ? size.icon : Math.min(size.icon, Tokens.icon.sm)
    property bool disabled
    // Draw a plain button in the secondary label colour instead of the accent:
    // for a disclosure chevron, which should not shout.
    property bool neutral

    readonly property color roleColor: role === Button.Destructive ? Theme.color.destructive : Theme.accent
    readonly property color foreground: neutral ? Theme.color.labelSecondary : style === Button.Filled ? Theme.color.onAccent : style === Button.Gray && role === Button.Normal ? Theme.color.label : roleColor
    readonly property bool iconOnly: text.length === 0

    signal activated
    signal secondaryActivated

    implicitWidth: iconOnly ? size.height : row.implicitWidth + size.padding * 2
    implicitHeight: size.height
    radius: capsule ? height / 2 : Math.min(Tokens.radius.sm, height / 2)
    // Plain fades to a transparent version of its own colour, not to black.
    color: style === Button.Filled ? roleColor : style === Button.Tinted ? Qt.alpha(roleColor, Tokens.state.tint) : style === Button.Gray ? Theme.color.fill : Qt.alpha(roleColor, 0)
    opacity: disabled ? Tokens.state.disabled : 1
    scale: press.down ? Tokens.state.pressScale : 1

    Behavior on scale {
        Anim {
            style: Tokens.motion.effectsFast
        }
    }

    Behavior on opacity {
        Anim {}
    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.spacing.xs

        Icon {
            visible: root.icon.length > 0
            name: root.icon
            size: root.iconSize
            color: root.foreground
            filled: root.iconFilled
        }

        Label {
            visible: !root.iconOnly
            text: root.text
            fontSize: root.size.fontSize
            color: root.foreground
        }
    }

    Pressable {
        id: press

        disabled: root.disabled
        radius: root.radius
        tint: root.style === Button.Filled ? Theme.color.onAccent : Theme.color.label
        onActivated: root.activated()
        onSecondaryActivated: root.secondaryActivated()
    }
}
