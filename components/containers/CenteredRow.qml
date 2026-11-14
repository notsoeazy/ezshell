import QtQuick
import QtQuick.Layouts
import qs.config

// A row that keeps one item in the middle however much is on either side.
// Both sides are as wide as the wider of the two, so the centre never moves
// when only one side has something to show. A side with nothing in it takes
// no space, and neither does the gap, so a lone centre item is just itself.
// The leading items sit against the left edge and the trailing ones against
// the right edge, in the order they are written, so the spare room of the
// narrower side is next to the centre and never at the edge.
//
//   leading    items to the left of the centre
//   center     the item that stays in the middle
//   trailing   items to the right of the centre
//   gap        least space between the centre and either side's items
//   spacing    space between items on the same side
Item {
    id: root

    property alias leading: leadingRow.data
    default property alias center: centerItem.data
    property alias trailing: trailingRow.data
    property real gap: Tokens.spacing.sm
    property real spacing: Tokens.spacing.sm

    // The width of each side: the wider one, plus the gap if there is one.
    readonly property real side: {
        const w = Math.max(leadingRow.implicitWidth, trailingRow.implicitWidth);
        return w > 0 ? w + gap : 0;
    }

    implicitWidth: side * 2 + centerItem.implicitWidth
    implicitHeight: Math.max(leadingRow.implicitHeight, centerItem.implicitHeight, trailingRow.implicitHeight)

    RowLayout {
        id: leadingRow

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.spacing
    }

    Item {
        id: centerItem

        anchors.centerIn: parent
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
        width: implicitWidth
        height: implicitHeight
    }

    RowLayout {
        id: trailingRow

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.spacing
    }
}
