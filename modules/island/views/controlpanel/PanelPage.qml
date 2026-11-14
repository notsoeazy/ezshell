import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.components.controls
import qs.modules.island

// Base of every control panel page: a fixed width, an optional header with a
// back button and title, and the page's content stacked below.
Item {
    id: root

    // Empty for the root page, which has no header.
    property string title
    // Extra items at the right of the header, such as the feature's switch.
    property alias accessory: accessories.data
    default property alias content: column.data

    implicitWidth: Tokens.island.panelWidth
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.md

        RowLayout {
            Layout.fillWidth: true
            visible: root.title.length > 0
            spacing: Tokens.spacing.xs

            IconButton {
                icon: "chevron_left"
                style: Button.Plain
                onActivated: IslandState.back()
            }

            Label {
                Layout.fillWidth: true
                text: root.title
                fontSize: Tokens.fontSize.lg
                emphasized: true
            }

            RowLayout {
                id: accessories

                spacing: Tokens.spacing.sm
            }
        }
    }
}
