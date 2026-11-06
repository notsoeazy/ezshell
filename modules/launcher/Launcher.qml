pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.state
import qs.themes

// Launcher mode (docs/design/08-launcher.png): search field, best matches, keyboard hints. The rows
// come from the provider the typed prefix picks (launcher/Registry.qml); this file knows no provider.
ColumnLayout {
    id: root

    property int selected: 0
    readonly property var results: registry.items

    function launch(item: var, modifier: int): void {
        registry.activate(item, modifier);
    }

    function previewUrl(item: var): string {
        const file = registry.active?.preview(item) ?? "";
        return file !== "" ? `file://${file}` : "";
    }

    function reveal(): void {
        list.positionViewAtIndex(root.selected, ListView.Contain);
    }

    function handleKey(event: KeyEvent): void {
        if (event.key === Qt.Key_Down)
            root.selected = Math.min(root.selected + 1, root.results.length - 1);
        else if (event.key === Qt.Key_Up)
            root.selected = Math.max(root.selected - 1, 0);
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            root.launch(root.results[root.selected] ?? null, event.modifiers);
        else if (event.key === Qt.Key_Escape)
            Visibility.close();
        else if (event.key !== Qt.Key_Delete || !registry.remove(root.results[root.selected] ?? null))
            return;
        event.accepted = true;
    }

    spacing: Appearance.island.launcher.rowGap
    // Typing starts over at the top; a row that only changes (an action asking to confirm) keeps its place.
    onResultsChanged: {
        root.selected = Math.min(root.selected, Math.max(0, root.results.length - 1));
        Qt.callLater(root.reveal);
    }
    onSelectedChanged: root.reveal()
    Component.onCompleted: {
        input.text = Visibility.launcherText;
        input.forceActiveFocus();
    }

    Connections {
        function onLauncherTextChanged(): void {
            if (Visibility.launcherText !== "")
                input.text = Visibility.launcherText;
        }

        target: Visibility
    }

    Registry {
        id: registry

        text: input.text
    }

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
                onTextChanged: root.selected = 0
            }
        }
    }

    // Up to maxResults rows show; longer lists (actions) scroll to keep the selection in view.
    ListView {
        id: list

        readonly property int shownRows: Math.min(list.count, Appearance.island.launcher.maxResults)

        Layout.fillWidth: true
        implicitHeight: Math.max(0, list.shownRows * (Appearance.island.launcher.row + list.spacing) - list.spacing)
        visible: list.count > 0
        spacing: Appearance.island.launcher.rowGap
        interactive: list.count > Appearance.island.launcher.maxResults
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: ScriptModel {
            values: root.results
        }

        delegate: StyledRect {
            id: row

            required property var modelData
            required property int index
            readonly property bool current: row.index === root.selected

            width: list.width
            implicitHeight: Appearance.island.launcher.row
            radius: Appearance.rounding.normal
            color: row.current ? Colors.surfaceContainerHigh : Colors.transparent

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.selected = row.index
                onClicked: mouse => root.launch(row.modelData, mouse.modifiers)
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

                    Image {
                        id: thumb

                        anchors.fill: parent
                        visible: thumb.source.toString() !== ""
                        source: root.previewUrl(row.modelData)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: Appearance.island.launcher.icon
                        sourceSize.height: Appearance.island.launcher.icon
                    }

                    IconImage {
                        anchors.fill: parent
                        anchors.margins: Appearance.spacing.small
                        visible: row.modelData.image !== undefined
                        source: visible ? Quickshell.iconPath(row.modelData.image, "application-x-executable") : ""
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        visible: row.modelData.icon !== undefined && !thumb.visible
                        text: row.modelData.icon ?? ""
                        color: Colors.surfaceFg
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: row.modelData.title
                        elide: Text.ElideRight
                        font.weight: Font.Medium
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: row.modelData.subtitle ?? ""
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
        text: registry.active?.emptyText ?? ""
        color: Colors.surfaceVariantFg
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: Appearance.island.launcher.footer
        Layout.leftMargin: Appearance.island.launcher.padding
        Layout.rightMargin: Appearance.island.launcher.padding
        spacing: Appearance.spacing.large

        StyledText {
            Layout.fillWidth: true
            text: registry.active?.hints ?? ""
            color: Colors.surfaceVariantFg
            font.pixelSize: Appearance.font.size.small
        }

        // With nothing typed, the prefixes on offer; clicking one types it.
        Repeater {
            model: input.text === "" ? registry.prefixed : []

            StyledText {
                id: hint

                required property Provider modelData

                text: `${hint.modelData.prefix} ${hint.modelData.name}`
                color: Colors.surfaceVariantFg
                font.pixelSize: Appearance.font.size.small
                font.weight: Font.Medium

                TapHandler {
                    onTapped: input.text = hint.modelData.prefix
                }
            }
        }
    }
}
