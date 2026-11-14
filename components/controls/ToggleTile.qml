import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.components
import qs.components.controls

// A Control Center tile. The whole tile toggles the feature; with `hasPage`, a
// separate chevron button opens its detail page. Right-click also asks for
// the page.
Surface {
    id: root

    required property string icon
    required property string title
    property string status
    property bool checked
    property bool hasPage
    property bool disabled

    signal toggled
    signal opened

    implicitWidth: Tokens.spacing.xxxl * 5.5
    implicitHeight: Tokens.control.tile
    radius: Tokens.radius.lg
    color: Theme.color.fillTertiary
    opacity: disabled ? Tokens.state.disabled : 1
    scale: press.down ? Tokens.state.pressScale : 1

    Behavior on scale {
        Anim {
            style: Tokens.motion.effectsFast
        }
    }

    // Below the content, so the chevron button on top takes its own clicks.
    Pressable {
        id: press

        disabled: root.disabled
        radius: root.radius
        onActivated: root.toggled()
        onSecondaryActivated: root.opened()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Tokens.spacing.sm
        spacing: Tokens.spacing.sm

        Rectangle {
            implicitWidth: Tokens.control.xxl
            implicitHeight: Tokens.control.xxl
            radius: height / 2
            color: root.checked ? Theme.accent : Theme.color.fill

            Behavior on color {
                ColorAnim {}
            }

            Icon {
                anchors.centerIn: parent
                name: root.icon
                filled: root.checked
                size: Tokens.icon.md
                color: root.checked ? Theme.color.onAccent : Theme.color.label
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Label {
                Layout.fillWidth: true
                text: root.title
                emphasized: true
            }

            Label {
                Layout.fillWidth: true
                visible: root.status.length > 0
                text: root.status
                fontSize: Tokens.fontSize.sm
                level: Label.Secondary
            }
        }

        IconButton {
            visible: root.hasPage
            icon: "chevron_right"
            disabled: root.disabled
            onActivated: root.opened()
        }
    }
}
