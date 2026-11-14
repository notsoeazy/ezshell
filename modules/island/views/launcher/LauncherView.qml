pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.components
import qs.components.containers
import qs.components.controls
import qs.modules.island
import qs.modules.island.views.launcher

// The launcher: one search field, one list. What is searched depends on how
// the search starts (see Modes). Up and Down move, Return runs, Escape clears
// the search and then closes.
View {
    id: root

    readonly property LauncherMode mode: Modes.modeFor(search.text)
    readonly property list<var> results: mode.results(Modes.queryFor(search.text)).slice(0, Config.launcher.maxResults)

    function run(index: int): void {
        if (index < 0 || index >= results.length)
            return;

        mode.activate(results[index]);
        // Unless the result opened another view, the launcher is done.
        if (IslandState.requested === "launcher")
            IslandState.close();
    }

    dismissible: true
    wantsKeyboard: true
    margin: Tokens.island.panelPadding

    onModeChanged: mode.prepare()
    Component.onCompleted: mode.prepare()

    ColumnLayout {
        spacing: Tokens.spacing.md

        Keys.onUpPressed: list.moveBy(-1)
        Keys.onDownPressed: list.moveBy(1)
        Keys.onPressed: event => {
            // Ctrl+J / Ctrl+N down, Ctrl+K / Ctrl+P up.
            if (!(event.modifiers & Qt.ControlModifier))
                return;

            if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                list.moveBy(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                list.moveBy(-1);
                event.accepted = true;
            }
        }

        SearchField {
            id: search

            Layout.preferredWidth: Tokens.island.sheetContentWidth
            size: Tokens.size.xxl
            capsule: true
            leadingIcon: root.mode.icon
            placeholder: root.mode.placeholder
            text: IslandState.launcherQuery
            onTextChanged: list.currentIndex = 0
            onAccepted: root.run(list.currentIndex)
            Component.onCompleted: focusInput()
        }

        Label {
            Layout.margins: Tokens.spacing.sm
            visible: root.results.length === 0
            text: root.mode.emptyText
            level: Label.Secondary
        }

        // The results sit straight on the island: no box, rows with a tile for
        // the picture, and the current row tinted with the accent.
        List {
            id: list

            Layout.fillWidth: true
            visible: root.results.length > 0
            // Six rows, so that no row is cut off half way.
            maxHeight: (Tokens.control.row + spacing) * 6 - spacing + inset * 2
            color: Qt.alpha(Theme.color.fillTertiary, 0)
            inset: 0
            spacing: Tokens.spacing.xxs
            highlightColor: Qt.alpha(Theme.accent, Tokens.state.current)
            highlightRadius: Tokens.radius.lg
            // "Enter" is part of the highlight, so it glides with it.
            highlightContent: Item {
                Label {
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.spacing.md
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Enter"
                    fontSize: Tokens.fontSize.sm
                    level: Label.Secondary
                }
            }
            model: root.results

            delegate: ListRow {
                required property var modelData
                required property int index

                width: ListView.view.width
                tile: true
                hoverInset: 0
                hoverRadius: Tokens.radius.lg
                title: modelData.title ?? ""
                subtitle: modelData.subtitle ?? ""
                icon: modelData.icon ?? ""
                image: modelData.image ?? ""
                glyph: modelData.glyph ?? ""
                glyphFont: modelData.nerd ? Tokens.font.nerd : ""
                separator: false
                onActivated: root.run(index)
            }
        }

        // The keys, under the list: what they do on the left, closing on the far right.
        KeyHints {
            Layout.fillWidth: true
            hints: [
                {
                    key: "󰓢",
                    text: "navigate"
                },
                {
                    key: "↵",
                    text: "enter"
                },
                {
                    key: ">",
                    text: "actions"
                },
                {
                    key: ":",
                    text: "clipboard"
                },
                {
                    key: ".",
                    text: "symbols"
                }
            ]
        }
    }
}
