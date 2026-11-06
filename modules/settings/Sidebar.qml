pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.themes

StyledRect {
    id: root

    // Raw page table from Settings.qml: { name, label, icon }.
    required property list<var> pages
    required property string current

    signal selected(string name)

    implicitWidth: Appearance.settings.sidebar
    color: Colors.surfaceContainer

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.settings.gap
        spacing: Appearance.spacing.small

        StyledText {
            Layout.margins: Appearance.settings.gap
            text: "Settings"
            font.pixelSize: Appearance.font.size.large
            font.weight: Font.DemiBold
        }

        Repeater {
            model: root.pages

            StyledRect {
                id: item

                required property var modelData
                readonly property bool active: item.modelData.name === root.current

                Layout.fillWidth: true
                implicitHeight: Appearance.control.height + Appearance.spacing.normal
                radius: height / 2
                color: item.active ? Colors.secondaryContainer : Colors.transparent

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Appearance.spacing.large
                    spacing: Appearance.settings.gap

                    MaterialIcon {
                        text: item.modelData.icon
                        fill: item.active ? 1 : 0
                        color: item.active ? Colors.secondaryContainerFg : Colors.surfaceVariantFg
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: item.modelData.label
                        color: item.active ? Colors.secondaryContainerFg : Colors.surfaceFg
                        font.weight: item.active ? Font.DemiBold : Font.Normal
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selected(item.modelData.name)
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
