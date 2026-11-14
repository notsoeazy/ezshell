import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.components
import qs.components.controls

// A row in a list or a grouped form: optional icon, title, optional subtitle,
// and trailing accessories (a switch, a value, a chevron) as children.
Item {
    id: root

    required property string title
    property string subtitle
    property string icon
    // In place of the icon: a picture (a path or URL), or a character such
    // as an emoji.
    property string image
    property string glyph
    // The font family the glyph is drawn in; empty for the usual one.
    property string glyphFont
    // Put the leading picture, icon or character on a rounded tile.
    property bool tile
    // The hover highlight's inset from the row's edge and its roundness; match
    // a list's current-row highlight when it has one.
    property real hoverInset: Tokens.spacing.xs
    property real hoverRadius: Tokens.radius.sm
    // Hairline under the row; turn off for the last row of a group.
    property bool separator: true
    // Whether the row itself can be clicked.
    property bool interactive: true
    property bool disabled
    default property alias trailing: accessories.data

    signal activated

    implicitWidth: Tokens.spacing.xxxl * 8
    // Every row is the same height, with one line of text or two.
    implicitHeight: Tokens.control.row
    opacity: disabled ? Tokens.state.disabled : 1

    // Below the content, so trailing controls take their own clicks.
    Pressable {
        anchors.margins: root.hoverInset
        radius: root.hoverRadius
        disabled: root.disabled || !root.interactive
        visible: root.interactive
        onActivated: root.activated()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Tokens.spacing.md
        anchors.rightMargin: Tokens.spacing.md
        spacing: Tokens.spacing.sm

        // The leading picture, icon or character, in a slot of one width so
        // that the text starts in the same place on every row.
        Item {
            visible: root.image.length > 0 || root.glyph.length > 0 || root.icon.length > 0
            implicitWidth: root.tile ? Tokens.control.lg : Tokens.icon.lg
            implicitHeight: implicitWidth

            Rectangle {
                anchors.fill: parent
                visible: root.tile
                radius: Tokens.radius.sm
                color: Theme.color.fill
            }

            IconImage {
                anchors.centerIn: parent
                visible: root.image.length > 0
                implicitSize: root.tile ? Tokens.icon.md : Tokens.icon.lg
                source: root.image
            }

            Label {
                anchors.centerIn: parent
                visible: root.glyph.length > 0 && root.image.length === 0
                text: root.glyph
                fontSize: Tokens.fontSize.xl
                font.family: root.glyphFont.length > 0 ? root.glyphFont : Tokens.font.family
            }

            Icon {
                anchors.centerIn: parent
                visible: root.icon.length > 0 && root.image.length === 0 && root.glyph.length === 0
                name: root.icon
                size: root.tile ? Tokens.icon.sm : Tokens.icon.md
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Label {
                Layout.fillWidth: true
                text: root.title
            }

            Label {
                Layout.fillWidth: true
                visible: root.subtitle.length > 0
                text: root.subtitle
                fontSize: Tokens.fontSize.sm
                level: Label.Secondary
            }
        }

        RowLayout {
            id: accessories

            spacing: Tokens.spacing.xs
        }
    }

    Separator {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Tokens.spacing.md
        anchors.rightMargin: Tokens.spacing.md
        visible: root.separator
    }
}
