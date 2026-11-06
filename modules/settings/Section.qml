import QtQuick
import QtQuick.Layouts
import qs.components
import qs.themes

// A titled group of rows on a settings page. Children go into the card.
ColumnLayout {
    id: root

    property string title: ""
    property string description: ""
    default property alias content: body.data

    Layout.fillWidth: true
    spacing: Appearance.spacing.normal

    StyledText {
        text: root.title
        font.pixelSize: Appearance.font.size.large
        font.weight: Font.DemiBold
    }

    StyledText {
        Layout.fillWidth: true
        visible: root.description !== ""
        text: root.description
        wrapMode: Text.Wrap
        color: Colors.surfaceVariantFg
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: body.implicitHeight + 2 * Appearance.settings.sectionPadding
        radius: Appearance.rounding.normal
        color: Colors.surfaceContainer

        ColumnLayout {
            id: body

            anchors.fill: parent
            anchors.margins: Appearance.settings.sectionPadding
            spacing: Appearance.settings.gap
        }
    }
}
