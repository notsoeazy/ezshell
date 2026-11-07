import QtQuick
import QtQuick.Layouts
import qs.components
import qs.modules.island.dashboard.cards
import qs.services
import qs.themes
import qs.utils

// Calendar tab: the clock card, then the month grid with today highlighted and month navigation. No events yet.
ColumnLayout {
    id: root

    // Months from the current one; reset by reopening the tab.
    property int offset: 0

    spacing: Appearance.island.expanded.gap

    ClockCard {
        Layout.fillWidth: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: Qt.formatDateTime(Calendar.monthStart(Time.date, root.offset), "MMMM yyyy")
            font.pixelSize: Appearance.font.size.large
            font.weight: Font.DemiBold
        }

        StyledButton {
            visible: root.offset !== 0
            text: "Today"
            onClicked: root.offset = 0
        }

        StyledButton {
            icon: "chevron_left"
            onClicked: root.offset--
        }

        StyledButton {
            icon: "chevron_right"
            onClicked: root.offset++
        }
    }

    MonthGrid {
        Layout.fillWidth: true
        offset: root.offset
        cell: Appearance.island.dashboard.bigDayCell
    }
}
