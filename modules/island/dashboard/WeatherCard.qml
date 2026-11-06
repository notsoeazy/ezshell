import QtQuick
import QtQuick.Layouts
import qs.components
import qs.modules.island.dashboard.cards
import qs.services
import qs.themes
import qs.utils

// Overview weather card (frame 14): place, current temperature and condition, today's high and low.
Card {
    id: root

    readonly property string place: Weather.place !== "" ? Weather.place : "Weather"

    icon: "location_on"
    title: root.place

    StyledText {
        visible: !Weather.ready
        text: Weather.error !== "" ? "Weather unavailable" : "Loading…"
        color: Colors.surfaceVariantFg
    }

    RowLayout {
        visible: Weather.ready
        spacing: Appearance.island.expanded.gap

        MaterialIcon {
            text: Icons.weather(Weather.code, Weather.isDay)
            size: Appearance.island.dashboard.heroClock
            color: Colors.tertiary
        }

        StyledText {
            text: `${Math.round(Weather.temperature)}°`
            font.pixelSize: Appearance.island.dashboard.heroClock
            font.weight: Font.DemiBold
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: Weather.ready
        text: `${Weather.condition} · H ${Math.round(Weather.high)}° L ${Math.round(Weather.low)}°`
        elide: Text.ElideRight
        color: Colors.surfaceVariantFg
        font.pixelSize: Appearance.font.size.small
    }
}
