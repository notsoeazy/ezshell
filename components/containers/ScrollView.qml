import QtQuick
import QtQuick.Layouts
import qs.components.containers

// HIG scroll view: children stack in a column that scrolls vertically, with an
// overlay scrollbar.
Flickable {
    id: root

    default property alias content: column.data
    property real padding
    property alias spacing: column.spacing

    implicitWidth: column.implicitWidth + padding * 2
    implicitHeight: contentHeight
    contentWidth: width
    contentHeight: column.implicitHeight + padding * 2
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: column

        x: root.padding
        y: root.padding
        width: root.width - root.padding * 2
        spacing: 0
    }

    ScrollBar {
        // On the view itself, not inside the scrolling content.
        parent: root
        flickable: root
    }
}
