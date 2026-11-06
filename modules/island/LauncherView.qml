pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.services
import qs.state
import qs.themes

// Launcher mode (docs/design/08-launcher.png): search field, best matches, keyboard hints.
ColumnLayout {
    id: root

    property int selected: 0
    readonly property list<DesktopEntry> results: Apps.search(input.text, Appearance.island.launcher.maxResults)

    function launch(entry: DesktopEntry): void {
        Apps.launch(entry);
        Visibility.close();
    }

    function handleKey(event: KeyEvent): void {
        if (event.key === Qt.Key_Down)
            root.selected = Math.min(root.selected + 1, root.results.length - 1);
        else if (event.key === Qt.Key_Up)
            root.selected = Math.max(root.selected - 1, 0);
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            root.launch(root.results[root.selected] ?? null);
        else if (event.key === Qt.Key_Escape)
            Visibility.close();
        else
            return;
        event.accepted = true;
    }

    spacing: Appearance.island.launcher.rowGap
    onResultsChanged: root.selected = 0
    Component.onCompleted: input.forceActiveFocus()

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: Appearance.island.launcher.search
        radius: height / 2
        color: Colors.surfaceContainerHigh

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Appearance.spacing.large
            anchors.rightMargin: Appearance.spacing.large
            spacing: Appearance.spacing.normal

            MaterialIcon {
                text: "search"
                color: Colors.surfaceVariantFg
            }

            TextInput {
                id: input

                Layout.fillWidth: true
                color: Colors.surfaceFg
                selectionColor: Colors.primary
                selectedTextColor: Colors.primaryFg
                font.family: Appearance.font.family
                font.pixelSize: Appearance.font.size.title
                focus: true
                Keys.onPressed: event => root.handleKey(event)
            }
        }
    }

    Repeater {
        model: ScriptModel {
            values: [...root.results]
        }

        StyledRect {
            id: row

            required property DesktopEntry modelData
            required property int index
            readonly property bool current: row.index === root.selected
            readonly property string subtitle: row.modelData.comment || row.modelData.genericName

            Layout.fillWidth: true
            implicitHeight: Appearance.island.launcher.row
            radius: Appearance.rounding.normal
            color: row.current ? Colors.surfaceContainerHigh : Colors.transparent

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.selected = row.index
                onClicked: root.launch(row.modelData)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Appearance.island.launcher.padding
                anchors.rightMargin: Appearance.island.launcher.padding
                spacing: Appearance.island.launcher.padding

                ClippingRectangle {
                    implicitWidth: Appearance.island.launcher.icon
                    implicitHeight: Appearance.island.launcher.icon
                    radius: Appearance.island.launcher.iconRadius
                    color: Colors.surfaceContainerHighest

                    IconImage {
                        anchors.fill: parent
                        anchors.margins: Appearance.spacing.small
                        source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: row.modelData.name
                        elide: Text.ElideRight
                        font.weight: Font.Medium
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: row.subtitle
                        elide: Text.ElideRight
                        color: Colors.surfaceVariantFg
                        font.pixelSize: Appearance.font.size.small
                    }
                }

                StyledText {
                    visible: row.current
                    text: "Enter"
                    color: Colors.surfaceVariantFg
                    font.pixelSize: Appearance.font.size.small
                    font.weight: Font.Medium
                }
            }
        }
    }

    StyledText {
        Layout.preferredHeight: Appearance.island.launcher.row
        Layout.fillWidth: true
        visible: root.results.length === 0
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        text: "No matching apps"
        color: Colors.surfaceVariantFg
    }

    StyledText {
        Layout.preferredHeight: Appearance.island.launcher.footer
        Layout.leftMargin: Appearance.island.launcher.padding
        verticalAlignment: Text.AlignVCenter
        text: "↑↓ navigate    ⏎ open    esc close"
        color: Colors.surfaceVariantFg
        font.pixelSize: Appearance.font.size.small
    }
}
