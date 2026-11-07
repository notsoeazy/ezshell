import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.themes

// Hero clock and the full date (the Calendar tab).
Card {
    id: root

    // Shrinks to fit: "12:13 PM" is much wider than "21:18".
    StyledText {
        Layout.fillWidth: true
        text: Qt.formatDateTime(Time.date, Time.timeFormat)
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: Appearance.font.size.title
        font.pixelSize: Appearance.island.dashboard.heroClock
        font.weight: Font.DemiBold
    }

    StyledText {
        text: Qt.formatDateTime(Time.date, "dddd, d MMMM")
        color: Colors.surfaceVariantFg
    }
}
