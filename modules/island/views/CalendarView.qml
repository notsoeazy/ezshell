pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.components
import qs.components.controls
import qs.services
import qs.modules.island

// A month calendar, with today marked.
View {
    id: root

    // The first day of the month being shown.
    property date month: new Date(Time.now.getFullYear(), Time.now.getMonth(), 1)
    readonly property int firstDayOfWeek: Qt.locale().firstDayOfWeek
    // How many cells of the previous month come before day 1.
    readonly property int lead: (month.getDay() - firstDayOfWeek + 7) % 7
    // Seven columns across the panel's width, rows as tall as a control.
    readonly property real cellWidth: Tokens.island.panelWidth / 7
    readonly property real cellHeight: Tokens.control.xl

    function shift(months: int): void {
        month = new Date(month.getFullYear(), month.getMonth() + months, 1);
    }

    // The date shown in cell `index` of the six-week grid.
    function dateAt(index: int): date {
        return new Date(month.getFullYear(), month.getMonth(), index - lead + 1);
    }

    function isToday(day: date): bool {
        return day.getFullYear() === Time.now.getFullYear() && day.getMonth() === Time.now.getMonth() && day.getDate() === Time.now.getDate();
    }

    dismissible: true
    margin: Tokens.island.panelPadding

    ColumnLayout {
        spacing: Tokens.spacing.md

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.xs

            Label {
                Layout.fillWidth: true
                text: Qt.formatDate(root.month, "MMMM yyyy")
                fontSize: Tokens.fontSize.lg
                emphasized: true
            }

            Button {
                text: "Today"
                size: Tokens.size.lg
                capsule: true
                onActivated: root.month = new Date(Time.now.getFullYear(), Time.now.getMonth(), 1)
            }

            IconButton {
                icon: "chevron_left"
                size: Tokens.size.lg
                onActivated: root.shift(-1)
            }

            IconButton {
                icon: "chevron_right"
                size: Tokens.size.lg
                onActivated: root.shift(1)
            }
        }

        GridLayout {
            columns: 7
            columnSpacing: 0
            rowSpacing: 0

            Repeater {
                model: 7

                Label {
                    required property int index

                    Layout.preferredWidth: root.cellWidth
                    text: Qt.locale().dayName((root.firstDayOfWeek + index) % 7, Locale.ShortFormat)
                    fontSize: Tokens.fontSize.sm
                    level: Label.Secondary
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Repeater {
                model: 42

                Item {
                    id: day

                    required property int index
                    readonly property date date: root.dateAt(index)
                    readonly property bool inMonth: date.getMonth() === root.month.getMonth()
                    readonly property bool today: root.isToday(date)

                    implicitWidth: root.cellWidth
                    implicitHeight: root.cellHeight

                    Rectangle {
                        anchors.centerIn: parent
                        width: Tokens.control.lg
                        height: Tokens.control.lg
                        radius: height / 2
                        color: Theme.accent
                        visible: day.today
                    }

                    Label {
                        anchors.centerIn: parent
                        text: day.date.getDate()
                        tabular: true
                        emphasized: day.today
                        color: day.today ? Theme.color.onAccent : day.inMonth ? Theme.color.label : Theme.color.labelTertiary
                    }
                }
            }
        }
    }
}
