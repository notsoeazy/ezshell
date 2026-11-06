import QtQuick
import QtQuick.Layouts
import qs.components
import qs.state
import qs.themes

// "… settings" link at the end of a section: opens the settings app on `page` and collapses the island.
RowLayout {
    id: root

    required property string label
    required property string page

    Layout.fillWidth: true
    Layout.preferredHeight: Appearance.control.height
    spacing: Appearance.spacing.normal

    MaterialIcon {
        text: "settings"
        color: Colors.surfaceVariantFg
    }

    StyledText {
        Layout.fillWidth: true
        text: root.label
        color: Colors.surfaceVariantFg
    }

    MaterialIcon {
        text: "open_in_new"
        size: Appearance.font.size.large
        color: Colors.surfaceVariantFg
    }

    TapHandler {
        onTapped: Visibility.open("settings", root.page)
    }
}
