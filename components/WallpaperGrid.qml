pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.themes

// Wallpaper thumbnails: a responsive paginated grid (Settings) that scales its 16:9 cells to fill the
// container's width, or a single-row strip (the island) that keeps the selection centered and slides.
// Takes the image list and optional cached thumbnail map in, reports picks, and never reads config.
Item {
    id: root

    // Image paths, already sorted.
    required property list<string> paths
    // Optional source path → cached JPEG thumbnail path map (from Wallpapers.thumbs).
    property var thumbs: ({})
    // Paths are shown relative to this folder, and the filter matches that relative path.
    property string folder: ""
    // Case-insensitive; "" shows everything.
    property string filter: ""
    // Drawn with a primary border: the image being previewed (grid); the strip borders its selection.
    property string selected: ""
    // Marked with a check: the wallpaper in use.
    property string checked: ""
    // Target thumbnail size; in grid mode this is the minimum width used to pick the column count,
    // and the actual thumbnails stretch to fill the container at the same aspect ratio.
    property int thumbWidth: Appearance.settings.thumbWidth
    property int thumbHeight: Appearance.settings.thumbHeight
    property int gap: Appearance.settings.gap
    // Rows per page in grid mode (0 = all rows on one page).
    property int pageRows: Appearance.settings.gridRows
    property int page: 0
    property bool strip: false
    property alias currentIndex: view.currentIndex
    readonly property list<string> allShown: root.filtered()
    readonly property int columns: Math.max(1, Math.floor((root.width + root.gap) / (root.thumbWidth + root.gap)))
    readonly property int perPage: !root.strip && root.pageRows > 0 ? root.columns * root.pageRows : root.allShown.length
    readonly property int pageCount: root.perPage > 0 ? Math.max(1, Math.ceil(root.allShown.length / root.perPage)) : 1
    readonly property int clampedPage: Math.max(0, Math.min(root.page, root.pageCount - 1))
    readonly property list<string> shown: root.pageItems()
    readonly property alias count: view.count
    readonly property string currentPath: root.shown[view.currentIndex] ?? ""
    readonly property real fitWidth: (root.width - (root.columns - 1) * root.gap) / root.columns
    readonly property real itemWidth: root.strip ? root.thumbWidth : Math.max(1, Math.floor(root.fitWidth))
    readonly property real aspect: root.thumbWidth > 0 ? root.thumbHeight / root.thumbWidth : 9 / 16
    readonly property real itemHeight: root.strip ? root.thumbHeight : Math.max(1, Math.round(root.itemWidth * root.aspect))
    readonly property int rows: root.strip ? 1 : Math.ceil(view.count / root.columns)
    readonly property int gridHeight: Math.max(0, root.rows * view.cellHeight - root.gap)
    readonly property bool paged: !root.strip && root.pageCount > 1

    // A click in the grid, or on the centered thumbnail of the strip. Keyboard callers read currentPath.
    signal picked(string path)
    // Emitted when the visible slice changes, so the caller can prioritise caching its thumbnails.
    signal visibleSliceChanged(list<string> items)

    function filtered(): list<string> {
        const needle = root.filter.trim().toLowerCase();
        return needle === "" ? root.paths : root.paths.filter(p => root.relative(p).toLowerCase().includes(needle));
    }

    function pageItems(): list<string> {
        if (root.strip || root.pageRows <= 0)
            return root.allShown;
        const start = root.clampedPage * root.perPage;
        return root.allShown.slice(start, start + root.perPage);
    }

    function relative(path: string): string {
        const prefix = root.folder.endsWith("/") ? root.folder : `${root.folder}/`;
        return root.folder !== "" && path.startsWith(prefix) ? path.slice(prefix.length) : path;
    }

    // Arrow keys move the selection; returns whether the key was one of them.
    function navigate(key: int): bool {
        if (key === Qt.Key_Left)
            view.moveCurrentIndexLeft();
        else if (key === Qt.Key_Right)
            view.moveCurrentIndexRight();
        else if (key === Qt.Key_Up && !root.strip)
            view.moveCurrentIndexUp();
        else if (key === Qt.Key_Down && !root.strip)
            view.moveCurrentIndexDown();
        else
            return false;
        return true;
    }

    function step(by: int): void {
        view.currentIndex = Math.max(0, Math.min(view.currentIndex + by, view.count - 1));
    }

    implicitHeight: root.gridHeight + (root.paged ? pager.implicitHeight + root.gap : 0)
    onFilterChanged: root.page = 0
    onShownChanged: root.visibleSliceChanged(root.shown)

    GridView {
        id: view

        // Each cell carries a trailing gap, so the grid view is one gap wider than the item: the last
        // column then ends flush with the right edge, like a Flow.
        width: root.strip ? root.width : root.width + root.gap
        height: root.strip ? root.itemHeight : root.gridHeight
        model: root.shown
        cellWidth: root.itemWidth + root.gap
        cellHeight: root.itemHeight + root.gap
        flow: root.strip ? GridView.FlowTopToBottom : GridView.FlowLeftToRight
        // The strip keeps the current thumbnail in a centered range, so moving slides the row; dragging
        // the row moves the selection with it. In grid mode both stay 0 so Qt never shifts originY.
        highlightRangeMode: root.strip ? GridView.StrictlyEnforceRange : GridView.NoHighlightRange
        preferredHighlightBegin: root.strip ? (root.width - root.itemWidth) / 2 : 0
        preferredHighlightEnd: root.strip ? (root.width - root.itemWidth) / 2 + view.cellWidth : 0
        highlightMoveDuration: Appearance.anim.scaled(Appearance.anim.normal)
        interactive: root.strip
        clip: true
        reuseItems: true
        keyNavigationWraps: false

        delegate: ClippingRectangle {
            id: thumb

            required property string modelData
            required property int index
            readonly property bool current: root.strip ? thumb.index === view.currentIndex : thumb.modelData === root.selected
            readonly property string sourcePath: root.thumbs[thumb.modelData] ?? thumb.modelData

            width: root.itemWidth
            height: root.itemHeight
            radius: Appearance.rounding.small
            color: Colors.surfaceContainerHigh
            border.width: thumb.current ? Appearance.settings.selectedBorder : 0
            border.color: Colors.primary
            opacity: root.strip && !thumb.current ? Appearance.island.expanded.secondaryOpacity : 1

            Behavior on opacity {
                Anim {}
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: img.status !== Image.Ready
                text: "image"
                color: Colors.outline
            }

            Image {
                id: img

                anchors.fill: parent
                source: `file://${thumb.sourcePath}`
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: !view.moving
                opacity: status === Image.Ready ? 1 : 0
                // Fixed decode size so resizing the Settings window never re-decodes thumbnails.
                sourceSize.width: Appearance.settings.thumbWidth * 2
                sourceSize.height: Appearance.settings.thumbHeight * 2

                Behavior on opacity {
                    Anim {}
                }
            }

            // On a black disc, so it reads on any image.
            StyledRect {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: Appearance.spacing.small
                implicitWidth: Appearance.control.check
                implicitHeight: Appearance.control.check
                radius: Appearance.rounding.full
                color: Colors.island
                visible: thumb.modelData === root.checked

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "check_circle"
                    fill: 1
                    color: Colors.primary
                }
            }

            // In the strip, a side thumbnail slides to the center first; the centered one applies.
            TapHandler {
                onTapped: {
                    if (root.strip && !thumb.current)
                        view.currentIndex = thumb.index;
                    else
                        root.picked(thumb.modelData);
                }
            }
        }
    }

    RowLayout {
        id: pager

        anchors.top: view.bottom
        anchors.topMargin: root.gap
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.paged
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: `${root.allShown.length} wallpapers · Page ${root.clampedPage + 1} of ${root.pageCount}`
            color: Colors.surfaceVariantFg
            font.pixelSize: Appearance.font.size.small
        }

        StyledButton {
            icon: "chevron_left"
            text: "Prev"
            enabled: root.clampedPage > 0
            onClicked: root.page = root.clampedPage - 1
        }

        StyledButton {
            icon: "chevron_right"
            text: "Next"
            enabled: root.clampedPage < root.pageCount - 1
            onClicked: root.page = root.clampedPage + 1
        }
    }

    // One thumbnail per wheel notch or touchpad swipe.
    WheelArea {
        anchors.fill: view
        enabled: root.strip
        horizontal: true
        onStepped: step => root.step(step)
    }
}
