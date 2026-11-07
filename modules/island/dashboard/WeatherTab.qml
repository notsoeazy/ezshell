pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.themes
import qs.utils

// Weather tab (docs/ISLAND-R1.md): now, the next 12 hours, the next 7 days. Weather fetches only while this
// tab is open and its data is older than the refresh interval (Expanded.qml turns it on).
Flickable {
    id: root

    // The week's coldest and warmest, so each day's bar sits on one shared scale.
    readonly property real weekLow: Math.min(...Weather.daily.map(d => d.low), 0)
    readonly property real weekHigh: Math.max(...Weather.daily.map(d => d.high), 1)

    function degrees(value: real): string {
        return `${Math.round(value)}°`;
    }

    // A day's low-to-high span as a share of the week's.
    function span(day: var): real {
        return root.share(day.high) - root.share(day.low);
    }

    function share(value: real): real {
        return root.weekHigh > root.weekLow ? (value - root.weekLow) / (root.weekHigh - root.weekLow) : 0;
    }

    implicitHeight: Math.min(column.implicitHeight, Appearance.island.expanded.pageMaxHeight)
    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: column

        width: root.width
        spacing: Appearance.island.expanded.gap

        StyledText {
            visible: !Weather.ready
            text: Weather.error !== "" ? Weather.error : "Loading…"
            color: Colors.surfaceVariantFg
        }

        // Now.
        RowLayout {
            Layout.fillWidth: true
            visible: Weather.ready
            spacing: Appearance.island.expanded.gap

            MaterialIcon {
                text: Icons.weather(Weather.code, Weather.isDay)
                size: Appearance.island.dashboard.weatherIcon
                color: Colors.primary
            }

            StyledText {
                text: `${Math.round(Weather.temperature)}${Weather.unit}`
                font.pixelSize: Appearance.island.dashboard.weatherHero
                font.weight: Font.DemiBold
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: Weather.condition
                    font.weight: Font.Medium
                }

                StyledText {
                    text: Weather.place
                    color: Colors.surfaceVariantFg
                }
            }

            ColumnLayout {
                spacing: 0

                StyledText {
                    Layout.alignment: Qt.AlignRight
                    text: `Feels ${Math.round(Weather.feelsLike)}${Weather.unit}`
                    color: Colors.surfaceVariantFg
                    font.pixelSize: Appearance.font.size.small
                }

                StyledText {
                    Layout.alignment: Qt.AlignRight
                    text: `${Weather.humidity}% humidity`
                    color: Colors.surfaceVariantFg
                    font.pixelSize: Appearance.font.size.small
                }

                StyledText {
                    Layout.alignment: Qt.AlignRight
                    text: `${Math.round(Weather.wind)} ${Weather.windUnit} wind`
                    color: Colors.surfaceVariantFg
                    font.pixelSize: Appearance.font.size.small
                }
            }
        }

        // The next 12 hours; the current one stands out.
        RowLayout {
            Layout.fillWidth: true
            visible: Weather.ready
            spacing: Appearance.spacing.small

            Repeater {
                model: Weather.hourly

                StyledRect {
                    id: hour

                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: capsule.implicitHeight + 2 * Appearance.spacing.normal
                    radius: Appearance.island.dashboard.hourCapsule / 2
                    color: hour.index === 0 ? Colors.primaryContainer : Colors.surfaceContainerHigh

                    ColumnLayout {
                        id: capsule

                        anchors.centerIn: parent
                        spacing: Appearance.spacing.small

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: hour.index === 0 ? "Now" : hour.modelData.time.slice(0, 2)
                            color: hour.index === 0 ? Colors.primaryContainerFg : Colors.surfaceVariantFg
                            font.pixelSize: Appearance.font.size.small
                        }

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: Icons.weather(hour.modelData.code, true)
                            color: hour.index === 0 ? Colors.primaryContainerFg : Colors.surfaceFg
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.degrees(hour.modelData.temperature)
                            color: hour.index === 0 ? Colors.primaryContainerFg : Colors.surfaceFg
                            font.pixelSize: Appearance.font.size.small
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }
        }

        // The next 7 days: name, icon, low, a range bar on the week's scale, high.
        Repeater {
            model: Weather.daily

            RowLayout {
                id: day

                required property var modelData
                required property int index

                Layout.fillWidth: true
                spacing: Appearance.island.expanded.gap

                StyledText {
                    Layout.preferredWidth: Appearance.island.dashboard.dayLabel
                    text: day.index === 0 ? "Today" : Qt.formatDate(day.modelData.day, "ddd")
                    font.weight: Font.Medium
                }

                MaterialIcon {
                    text: Icons.weather(day.modelData.code, true)
                }

                StyledText {
                    Layout.preferredWidth: Appearance.island.dashboard.dayLabel / 2
                    horizontalAlignment: Text.AlignRight
                    text: root.degrees(day.modelData.low)
                    color: Colors.surfaceVariantFg
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: Appearance.island.dashboard.rangeBar
                    radius: height / 2
                    color: Colors.surfaceContainerHighest

                    StyledRect {
                        x: parent.width * root.share(day.modelData.low)
                        width: Math.max(parent.height, parent.width * root.span(day.modelData))
                        height: parent.height
                        radius: height / 2
                        color: Colors.primary
                    }
                }

                StyledText {
                    Layout.preferredWidth: Appearance.island.dashboard.dayLabel / 2
                    text: root.degrees(day.modelData.high)
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
