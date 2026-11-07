pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.components
import qs.services
import qs.state
import qs.themes

// Window switcher (ROADMAP F10): recent windows as app tiles, the selection highlighted, its title and
// workspace below. Keys are caught in ModeLayers, which stays visible while this fades in; a click
// picks a window.
ColumnLayout {
    id: root

    readonly property list<HyprlandToplevel> windows: Hypr.recent
    readonly property int count: root.windows.length
    readonly property int current: Hypr.recentIndex(Visibility.switcherStep)
    readonly property HyprlandToplevel selected: Hypr.recentAt(Visibility.switcherStep)
    readonly property real tile: Appearance.island.switcher.tile
    readonly property real gap: Appearance.spacing.normal
    readonly property real fullRow: root.count * (root.tile + root.gap) - root.gap
    readonly property real rowWidth: Math.min(root.fullRow, Appearance.island.switcher.maxRow)
    // The title line may be wider than a short row of tiles.
    readonly property real textWidth: Math.max(root.rowWidth, Appearance.island.switcher.minText)

    function appOf(window: HyprlandToplevel): var {
        return Apps.entryFor(window?.lastIpcObject.class ?? "");
    }

    // "Firefox · Workspace 2"
    function detail(window: HyprlandToplevel): string {
        const app = root.appOf(window)?.name ?? window?.lastIpcObject.class ?? "";
        return [app, `Workspace ${window?.workspace?.id ?? ""}`].filter(s => s !== "").join(" · ");
    }

    spacing: Appearance.island.expanded.gap

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        visible: root.count === 0
        text: "No windows open"
        color: Colors.surfaceVariantFg
    }

    ListView {
        id: list

        Layout.alignment: Qt.AlignHCenter
        visible: root.count > 0
        implicitWidth: root.rowWidth
        implicitHeight: root.tile
        orientation: ListView.Horizontal
        spacing: root.gap
        interactive: false
        clip: true
        model: root.windows
        currentIndex: root.current
        // Keeps the selection in view when there are more windows than fit.
        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: root.tile
        preferredHighlightEnd: list.width - root.tile
        highlightMoveDuration: Appearance.anim.scaled(Appearance.anim.normal)

        delegate: StyledRect {
            id: tile

            required property HyprlandToplevel modelData
            required property int index
            readonly property bool selected: tile.index === root.current
            readonly property var entry: root.appOf(tile.modelData)

            implicitWidth: root.tile
            implicitHeight: root.tile
            radius: Appearance.island.switcher.tileRadius
            color: tile.selected ? Colors.primaryContainer : Colors.surfaceContainerHigh
            border.width: tile.selected ? Appearance.control.borderWidth : 0
            border.color: Colors.primary

            Behavior on color {
                CAnim {}
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: Appearance.island.switcher.icon
                source: Quickshell.iconPath(tile.entry?.icon ?? "", "application-x-executable")
            }

            TapHandler {
                onTapped: Visibility.pickWindow(tile.index)
            }
        }
    }

    ColumnLayout {
        // A fixed width, so the pill doesn't change size with each title as the selection moves.
        Layout.preferredWidth: root.textWidth
        visible: root.selected !== null
        spacing: 0

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.selected?.title ?? ""
            elide: Text.ElideRight
            font.weight: Font.DemiBold
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.detail(root.selected)
            color: Colors.surfaceVariantFg
            font.pixelSize: Appearance.font.size.small
        }
    }
}
