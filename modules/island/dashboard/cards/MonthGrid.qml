pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.themes
import qs.utils

// Month grid with weekday initials and today highlighted. Used by the Overview card and the Calendar tab.
GridLayout {
    id: root

    property int offset: 0
    property int cell: Appearance.island.dashboard.dayCell
    readonly property date first: Calendar.monthStart(Time.date, root.offset)

    columns: 7
    rowSpacing: 0
    columnSpacing: 0

    Repeater {
        model: Calendar.weekdays

        StyledText {
            required property string modelData

            Layout.preferredWidth: root.cell
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: modelData
            color: Colors.surfaceVariantFg
            font.pixelSize: Appearance.font.size.small
        }
    }

    Repeater {
        model: Calendar.cells(root.first, Time.date)

        Item {
            id: day

            required property var modelData

            Layout.preferredWidth: root.cell
            Layout.preferredHeight: root.cell
            Layout.fillWidth: true

            // A fixed circle centred in the cell, so wide cells don't stretch the highlight.
            StyledRect {
                anchors.centerIn: parent
                width: root.cell
                height: root.cell
                radius: height / 2
                color: day.modelData.today ? Colors.primary : Colors.transparent
            }

            StyledText {
                anchors.centerIn: parent
                text: day.modelData.day
                color: day.modelData.today ? Colors.primaryFg : Colors.surfaceFg
                opacity: day.modelData.inMonth ? 1 : Appearance.island.dimmedOpacity
                font.pixelSize: Appearance.font.size.small
                font.weight: day.modelData.today ? Font.DemiBold : Font.Normal
            }
        }
    }
}
