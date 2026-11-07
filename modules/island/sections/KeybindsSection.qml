pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.themes

// Keybind cheat sheet (ROADMAP F9): search over Hyprland's binds, grouped by the description's prefix
// ("Media: Play or pause"). Described binds without a prefix go under "Other", binds without a
// description last under "No description". ↑/↓ and Page Up/Down scroll; Esc collapses (Expanded.qml).
ColumnLayout {
    id: root

    readonly property string query: search.text.trim().toLowerCase()
    readonly property var shown: Keybinds.binds.filter(b => root.matches(b))
    readonly property var groups: root.grouped(root.shown)
    // The page cap minus what sits above the list.
    readonly property real above: search.implicitHeight + (hint.visible ? hint.implicitHeight + root.spacing : 0)
    readonly property real listMax: Appearance.island.expanded.pageMaxHeight - root.above - root.spacing

    function matches(bind: var): bool {
        return root.query === "" || `${bind.keys} ${bind.group} ${bind.text}`.toLowerCase().includes(root.query);
    }

    function groupOf(bind: var): string {
        if (bind.text === "")
            return "No description";
        return bind.group !== "" ? bind.group : "Other";
    }

    // Named groups alphabetically, then "Other", then "No description".
    function rank(name: string): int {
        return name === "No description" ? 2 : name === "Other" ? 1 : 0;
    }

    function grouped(binds: var): var {
        const byName = {};
        for (const bind of binds) {
            const name = root.groupOf(bind);
            byName[name] = [...(byName[name] ?? []), bind];
        }
        const names = Object.keys(byName).sort((a, b) => root.rank(a) - root.rank(b) || a.localeCompare(b));
        return names.map(name => ({
                    name: name,
                    binds: byName[name]
                }));
    }

    function scroll(by: real): void {
        list.contentY = Math.max(0, Math.min(list.contentY + by, list.contentHeight - list.height));
    }

    function handleKey(event: KeyEvent): void {
        const line = Appearance.island.keybinds.row;
        const steps = {
            [Qt.Key_Down]: line,
            [Qt.Key_Up]: -line,
            [Qt.Key_PageDown]: list.height,
            [Qt.Key_PageUp]: -list.height
        };
        if (steps[event.key] === undefined)
            return;
        root.scroll(steps[event.key]);
        event.accepted = true;
    }

    spacing: Appearance.island.expanded.gap
    // Back from under the polkit prompt: the search field takes the keyboard again.
    onVisibleChanged: {
        if (visible)
            search.focusInput();
    }
    Component.onCompleted: search.focusInput()

    StyledTextField {
        id: search

        Layout.fillWidth: true
        placeholder: `Search ${Keybinds.binds.length} keybinds`
        onKeyPressed: event => root.handleKey(event)
        onTextChanged: list.contentY = 0
    }

    StyledText {
        id: hint

        Layout.fillWidth: true
        visible: Keybinds.binds.length > 0 && Keybinds.described === 0
        text: "No bind has a description yet: add { description = \"Group: Action\" } in Hyprland."
        wrapMode: Text.WordWrap
        color: Colors.surfaceVariantFg
        font.pixelSize: Appearance.font.size.small
    }

    Flickable {
        id: list

        Layout.fillWidth: true
        implicitHeight: Math.min(groups.implicitHeight, root.listMax)
        contentHeight: groups.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: groups

            width: list.width
            spacing: Appearance.island.expanded.gap

            StyledText {
                visible: root.shown.length === 0
                text: Keybinds.binds.length === 0 ? "No keybinds found" : "No matches"
                color: Colors.surfaceVariantFg
            }

            Repeater {
                model: root.groups

                ColumnLayout {
                    id: group

                    required property var modelData

                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: group.modelData.name
                        color: Colors.primary
                        font.pixelSize: Appearance.font.size.small
                        font.weight: Font.DemiBold
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: Appearance.spacing.small
                        columnSpacing: Appearance.island.expanded.gap

                        Repeater {
                            model: group.modelData.binds

                            BindRow {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                            }
                        }
                    }
                }
            }
        }
    }

    // One bind: what it does on the left, its keys as caps on the right.
    component BindRow: StyledRect {
        id: row

        required property var modelData

        implicitHeight: Appearance.island.keybinds.row
        radius: Appearance.island.keybinds.rowRadius
        color: Colors.surfaceContainerHigh

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Appearance.island.control.cardSidePadding
            anchors.rightMargin: Appearance.island.keybinds.capGap
            spacing: Appearance.spacing.normal

            StyledText {
                Layout.fillWidth: true
                text: row.modelData.text !== "" ? row.modelData.text : row.modelData.submap
                elide: Text.ElideRight
                color: row.modelData.text !== "" ? Colors.surfaceFg : Colors.surfaceVariantFg
            }

            Repeater {
                model: row.modelData.keys.split(" + ")

                StyledRect {
                    id: cap

                    required property string modelData

                    readonly property real padded: capText.implicitWidth + 2 * Appearance.island.keybinds.capPadding

                    implicitWidth: Math.max(cap.padded, Appearance.island.keybinds.cap)
                    implicitHeight: Appearance.island.keybinds.cap
                    radius: Appearance.island.keybinds.capRadius
                    color: Colors.surfaceContainerHighest

                    StyledText {
                        id: capText

                        anchors.centerIn: parent
                        text: cap.modelData
                        font.pixelSize: Appearance.font.size.small
                        font.weight: Font.Medium
                    }
                }
            }
        }
    }
}
