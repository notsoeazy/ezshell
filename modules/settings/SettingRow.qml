import QtQuick
import QtQuick.Layouts
import qs.components
import qs.themes

// One row: optional icon, label and sublabel on the left, controls (the children) on the right.
RowLayout {
    id: root

    property string icon: ""
    property string label: ""
    property string sublabel: ""
    default property alias controls: trailing.data

    Layout.fillWidth: true
    Layout.minimumHeight: Appearance.settings.row
    spacing: Appearance.settings.gap

    MaterialIcon {
        visible: root.icon !== ""
        text: root.icon
        color: Colors.surfaceVariantFg
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        StyledText {
            Layout.fillWidth: true
            text: root.label
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.sublabel !== ""
            text: root.sublabel
            elide: Text.ElideRight
            color: Colors.surfaceVariantFg
            font.pixelSize: Appearance.font.size.small
        }
    }

    RowLayout {
        id: trailing

        spacing: Appearance.spacing.normal
    }
}
