import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.themes

// Hero clock and full date; with `showWeather`, a one-line weather summary under it (frame 15).
Card {
    id: root

    property bool showWeather: false

    // Shrinks to fit: "12:13 PM" is much wider than "21:18" in the narrow bento card.
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

    ColumnLayout {
        visible: root.showWeather && Weather.ready
        spacing: 0

        StyledText {
            text: `${Math.round(Weather.temperature)}${Weather.unit} · ${Weather.condition}`
            font.weight: Font.DemiBold
        }

        StyledText {
            text: `${Weather.place} · ${Weather.humidity}% humidity`
            color: Colors.surfaceVariantFg
            font.pixelSize: Appearance.font.size.small
        }
    }
}
