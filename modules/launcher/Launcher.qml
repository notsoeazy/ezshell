pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.state
import qs.themes

// Launcher mode (docs/design/08-launcher.png): search field, best matches, keyboard hints. The rows
// come from the provider the typed prefix picks (launcher/Registry.qml); this file knows no provider.
ColumnLayout {
    id: root

    property int selected: 0
    readonly property var results: registry.items
    readonly property bool grid: registry.active?.layout === "grid"
    // Arrow steps: rows in a list; cells, and a row of cells up or down, in a grid.
    readonly property int rowStep: root.grid ? cells.columns : 1
    readonly property var current: root.results[root.selected] ?? null
    readonly property string status: root.current ? registry.active?.status(root.current) ?? "" : ""
    readonly property list<string> chips: registry.active?.chips ?? []

    function launch(item: var, modifier: int): void {
        registry.activate(item, modifier);
    }

    function previewUrl(item: var): string {
        const file = registry.active?.preview(item) ?? "";
        return file !== "" ? `file://${file}` : "";
    }

    function reveal(): void {
        if (root.grid)
            cells.positionViewAtIndex(root.selected, GridView.Contain);
        else
            list.positionViewAtIndex(root.selected, ListView.Contain);
    }

    function move(by: int): void {
        root.selected = Math.max(0, Math.min(root.selected + by, root.results.length - 1));
    }

    // Left and Right stay with the search field in a list, and move between cells in a grid.
    function cycleChip(by: int): void {
        const provider = registry.active;
        const count = provider.chips.length;
        const index = provider.chips.indexOf(provider.chip);
        provider.chip = provider.chips[((index + by) % count + count) % count];
        root.selected = 0;
    }

    function handleKey(event: KeyEvent): void {
        if ((event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) && root.chips.length > 0)
            root.cycleChip(event.key === Qt.Key_Backtab ? -1 : 1);
        else if (event.key === Qt.Key_Down)
            root.move(root.rowStep);
        else if (event.key === Qt.Key_Up)
            root.move(-root.rowStep);
        else if (root.grid && (event.key === Qt.Key_Left || event.key === Qt.Key_Right))
            root.move(event.key === Qt.Key_Right ? 1 : -1);
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            root.launch(root.current, event.modifiers);
        else if (event.key === Qt.Key_Escape)
            Visibility.close();
        else if (event.key !== Qt.Key_Delete || !registry.remove(root.current))
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
    // Back from under the polkit prompt: the search field takes the keyboard again.
    onVisibleChanged: {
        if (visible)
            input.forceActiveFocus();
    }
    Component.onCompleted: {
        input.text = Visibility.launcherText;
        input.forceActiveFocus();
    }

    Connections {
        function onLauncherRequestChanged(): void {
            input.text = Visibility.launcherText;
        }

        target: Visibility
    }

    Registry {
        id: registry

        text: input.text
    }

    // One model, handed to whichever view the active provider's layout uses.
    ScriptModel {
        id: results

        values: root.results
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
        model: root.grid ? null : results

        delegate: LauncherRow {
            id: row

            width: list.width
            current: row.index === root.selected
            picture: root.previewUrl(row.modelData)
            onHovered: root.selected = row.index
            onClicked: modifiers => root.launch(row.modelData, modifiers)
        }
    }

    Row {
        id: chipRow

        Layout.fillWidth: true
        visible: root.chips.length > 0
        spacing: Appearance.spacing.small

        Repeater {
            model: root.chips

            StyledRect {
                id: chip

                required property string modelData
                readonly property bool active: chip.modelData === registry.active?.chip

                implicitWidth: label.implicitWidth + 2 * Appearance.island.chipPadding
                implicitHeight: Appearance.island.chipHeight
                radius: height / 2
                color: chip.active ? Colors.primary : Colors.surfaceContainerHigh

                StyledText {
                    id: label

                    anchors.centerIn: parent
                    text: chip.modelData
                    color: chip.active ? Colors.primaryFg : Colors.surfaceFg
                    font.pixelSize: Appearance.font.size.small
                    font.weight: Font.Medium
                }

                TapHandler {
                    onTapped: {
                        registry.active.chip = chip.modelData;
                        root.selected = 0;
                    }
                }
            }
        }
    }

    // As tall as the list's rows at most; the columns that fit, centered.
    GridView {
        id: cells

        readonly property int columns: Math.max(1, Math.floor(width / cells.cellWidth))
        // The chip row takes from the same height, so the launcher never grows past its tallest list.
        readonly property int chipsHeight: chipRow.visible ? chipRow.implicitHeight + Appearance.island.launcher.rowGap : 0
        readonly property int maxRows: Math.floor((Appearance.island.launcher.rowsHeight - cells.chipsHeight) / cells.cellHeight)
        readonly property int rows: Math.min(Math.ceil(cells.count / cells.columns), cells.maxRows)

        Layout.fillWidth: true
        implicitHeight: cells.rows * cells.cellHeight
        leftMargin: (cells.width - cells.columns * cells.cellWidth) / 2
        visible: cells.count > 0
        cellWidth: registry.active?.cellWidth ?? Appearance.island.launcher.cell
        cellHeight: Appearance.island.launcher.cell
        interactive: cells.count > cells.columns * cells.maxRows
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.grid ? results : null

        delegate: LauncherCell {
            id: cell

            width: cells.cellWidth
            height: cells.cellHeight
            current: cell.index === root.selected
            onHovered: root.selected = cell.index
            onClicked: modifiers => root.launch(cell.modelData, modifiers)
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
            text: root.status !== "" ? root.status : registry.active?.hints ?? ""
            elide: Text.ElideRight
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
