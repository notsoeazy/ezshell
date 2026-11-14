import QtQuick
import qs.config
import qs.theme
import qs.components

// A rounded, padded container for one thing, such as a media row: its content
// is the single child, which it is as big as, plus the padding. Give the child
// `anchors.left` and `anchors.right` to have it follow the card's width.
//
//   padding   space between the edge and the content, on every side
//   radius    corner radius; Tokens.radius.full makes a capsule
//   color     fill (default a soft fill that sits on the island)
//   interactive  whether the whole card can be clicked (`activated`)
//   feedback     whether it shows a hover and press highlight when interactive
Rectangle {
    id: root

    default property alias content: inner.data
    property real padding: Tokens.spacing.md
    property bool interactive
    property bool feedback: true

    signal activated

    implicitWidth: inner.implicitWidth + padding * 2
    implicitHeight: inner.implicitHeight + padding * 2
    radius: Tokens.radius.lg
    color: Theme.color.fillTertiary

    Behavior on color {
        ColorAnim {}
    }

    // Under the content, so that buttons inside the card are clicked first.
    Pressable {
        radius: root.radius
        disabled: !root.interactive
        feedback: root.feedback
        onActivated: root.activated()
    }

    Item {
        id: inner

        anchors.fill: parent
        anchors.margins: root.padding
        implicitWidth: children.length > 0 ? children[0].implicitWidth : 0
        implicitHeight: children.length > 0 ? children[0].implicitHeight : 0
    }
}
