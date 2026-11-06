import QtQuick
import QtQuick.Layouts
import qs.modules.island.dashboard.cards
import qs.themes

// Overview bento (frame 14). Top row: clock, weather, media. Bottom row: system, calendar, quick toggles.
ColumnLayout {
    id: root

    required property string screenName

    // Width of card `index` in a row split by `shares`, after the gaps between the cards.
    function share(shares: list<real>, index: int): real {
        const total = shares.reduce((a, b) => a + b, 0);
        const free = root.width - (shares.length - 1) * Appearance.island.expanded.gap;
        return free * shares[index] / total;
    }

    spacing: Appearance.island.expanded.gap

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: Appearance.island.dashboard.topRow
        spacing: Appearance.island.expanded.gap

        ClockCard {
            Layout.fillHeight: true
            Layout.preferredWidth: root.share(Appearance.island.dashboard.topShares, 0)
        }

        WeatherCard {
            Layout.fillHeight: true
            Layout.preferredWidth: root.share(Appearance.island.dashboard.topShares, 1)
        }

        MediaCard {
            Layout.fillHeight: true
            Layout.preferredWidth: root.share(Appearance.island.dashboard.topShares, 2)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.island.expanded.gap

        SystemCard {
            Layout.fillHeight: true
            Layout.preferredWidth: root.share(Appearance.island.dashboard.bottomShares, 0)
        }

        Card {
            Layout.fillHeight: true
            Layout.preferredWidth: root.share(Appearance.island.dashboard.bottomShares, 1)
            icon: "calendar_month"
            title: Qt.formatDateTime(new Date(), "MMMM yyyy")

            MonthGrid {
                Layout.fillWidth: true
            }
        }

        QuickToggles {
            Layout.fillHeight: true
            Layout.preferredWidth: root.share(Appearance.island.dashboard.bottomShares, 2)
            screenName: root.screenName
        }
    }
}
