import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.themes

RowLayout {
    id: root

    spacing: Appearance.spacing.normal

    StyledText {
        text: Qt.formatDateTime(Time.date, Time.timeFormat)
        font.pixelSize: Appearance.font.size.clock
        font.weight: Font.DemiBold
    }

    StyledText {
        text: Qt.formatDateTime(Time.date, "ddd d MMM")
        color: Colors.surfaceVariantFg
        font.weight: Font.Medium
    }
}
