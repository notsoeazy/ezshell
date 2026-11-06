import QtQuick
import QtQuick.Layouts
import qs.components
import qs.themes

// Dashboard card (ISLAND.md card table): surfaceContainerHigh, radius and padding 16, optional header
// with a 16px icon and a small label. Children go below the header.
StyledRect {
    id: root

    property string icon: ""
    property string title: ""
    default property alias content: body.data

    implicitHeight: column.implicitHeight + 2 * Appearance.island.expanded.cardPadding
    radius: Appearance.island.expanded.cardRadius
    color: Colors.surfaceContainerHigh

    ColumnLayout {
        id: column

        anchors.fill: parent
        anchors.margins: Appearance.island.expanded.cardPadding
        spacing: Appearance.island.expanded.gap

        RowLayout {
            visible: root.title !== ""
            spacing: Appearance.spacing.normal

            MaterialIcon {
                text: root.icon
                size: Appearance.island.dashboard.headerIcon
                color: Colors.surfaceVariantFg
            }

            StyledText {
                text: root.title
                color: Colors.surfaceVariantFg
                font.pixelSize: Appearance.font.size.small
                font.weight: Font.Medium
            }
        }

        ColumnLayout {
            id: body

            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Appearance.island.expanded.gap
        }
    }
}
