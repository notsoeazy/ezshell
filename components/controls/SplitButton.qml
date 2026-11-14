import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.components

// A button in two parts (HIG pull-down button): the main part does the
// action, the chevron opens the choices for how. It does not hold the
// choices itself; show an OptionList when `menuActivated` fires.
//
//   text, icon   the main part
//   size         one of Tokens.size
//   style        Button.Gray or Button.Filled; role Button.Destructive
//   expanded     whether the choices are showing: turns the chevron
ClippingRectangle {
    id: root

    property string text
    property string icon
    property Tokens.ControlSize size: Tokens.size.md
    property int style: Button.Gray
    property int role: Button.Normal
    property bool expanded
    property bool disabled

    readonly property color roleColor: role === Button.Destructive ? Theme.color.destructive : Theme.accent
    readonly property color foreground: style === Button.Filled ? Theme.color.onAccent : Theme.color.label

    signal activated
    signal menuActivated

    implicitWidth: row.implicitWidth
    implicitHeight: size.height
    radius: height / 2
    color: style === Button.Filled ? roleColor : Theme.color.fill
    opacity: disabled ? Tokens.state.disabled : 1

    Behavior on color {
        ColorAnim {}
    }

    RowLayout {
        id: row

        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: main.implicitWidth + root.size.padding * 2

            RowLayout {
                id: main

                anchors.centerIn: parent
                spacing: Tokens.spacing.xs

                Icon {
                    visible: root.icon.length > 0
                    name: root.icon
                    size: Math.min(root.size.icon, Tokens.icon.sm)
                    color: root.foreground
                }

                Label {
                    text: root.text
                    fontSize: root.size.fontSize
                    color: root.foreground
                    tabular: true
                }
            }

            Pressable {
                disabled: root.disabled
                tint: root.foreground
                onActivated: root.activated()
                onSecondaryActivated: root.menuActivated()
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.topMargin: Tokens.spacing.xs
            Layout.bottomMargin: Tokens.spacing.xs
            implicitWidth: 1
            color: root.foreground
            opacity: Tokens.state.disabled
        }

        Item {
            Layout.fillHeight: true
            implicitWidth: root.size.height

            Icon {
                anchors.centerIn: parent
                name: "expand_more"
                size: Math.min(root.size.icon, Tokens.icon.sm)
                color: root.foreground
                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    Anim {
                        style: Tokens.motion.spatialFast
                    }
                }
            }

            Pressable {
                disabled: root.disabled
                tint: root.foreground
                onActivated: root.menuActivated()
            }
        }
    }
}
