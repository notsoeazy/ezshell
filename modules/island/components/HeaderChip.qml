import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components

// One item of a header row: its content, side by side, with a hover and
// press highlight that reaches a little past the content. The content itself
// stays where it is, so it lines up with whatever is above or below it; only
// the highlight has the padding. With `interactive` off it has no highlight
// and clicks go through to the island.
//
//   padding       how far the highlight reaches past the content
//   interactive   whether it can be clicked
//   activated     the click
Item {
    id: root

    default property alias content: row.data
    property real padding: Tokens.spacing.sm
    property bool interactive: true

    signal activated

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row

        anchors.fill: parent
        spacing: Tokens.spacing.sm
    }

    Pressable {
        anchors.margins: -root.padding
        radius: Tokens.radius.md
        disabled: !root.interactive
        onActivated: root.activated()
    }
}
