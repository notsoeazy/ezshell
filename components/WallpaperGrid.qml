pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.themes

// Wallpaper thumbnails, as a grid that grows to show every row (inside a page that scrolls) or as a
// single-row strip that keeps the selection centered and slides. A GridView either way, so only the
// visible thumbnails (plus a small buffer) exist and decode. Takes the image list in, reports picks,
// and never reads config.
Item {
    id: root

    // Image paths, already sorted.
    required property list<string> paths
    // Paths are shown relative to this folder, and the filter matches that relative path.
    property string folder: ""
    // Case-insensitive; "" shows everything.
    property string filter: ""
    // Drawn with a primary border: the image being previewed (grid); the strip borders its selection.
    property string selected: ""
    // Marked with a check: the wallpaper in use.
    property string checked: ""
    property int thumbWidth: Appearance.settings.thumbWidth
    property int thumbHeight: Appearance.settings.thumbHeight
    property int gap: Appearance.settings.gap
    property bool strip: false
    property alias currentIndex: view.currentIndex
    readonly property alias count: view.count
    readonly property list<string> shown: root.filtered()
    readonly property string currentPath: root.shown[view.currentIndex] ?? ""
    readonly property int columns: Math.max(1, Math.floor(view.width / view.cellWidth))
    readonly property int rows: root.strip ? 1 : Math.ceil(view.count / root.columns)

    // A click in the grid, or on the centered thumbnail of the strip. Keyboard callers read currentPath.
    signal picked(string path)

    function filtered(): list<string> {
        const needle = root.filter.trim().toLowerCase();
        return needle === "" ? root.paths : root.paths.filter(p => root.relative(p).toLowerCase().includes(needle));
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

    // The last row's gap isn't needed below it.
    implicitHeight: Math.max(0, root.rows * view.cellHeight - root.gap)

    GridView {
        id: view

        // Each cell carries a trailing gap, so the grid view is one gap wider than the item: the last
        // column then ends flush with the right edge, like a Flow.
        width: root.strip ? root.width : root.width + root.gap
        height: root.strip ? root.thumbHeight : root.height
        model: root.shown
        cellWidth: root.thumbWidth + root.gap
        cellHeight: root.thumbHeight + root.gap
        flow: root.strip ? GridView.FlowTopToBottom : GridView.FlowLeftToRight
        // The strip keeps the current thumbnail in a centered range, so moving slides the row; dragging
        // the row moves the selection with it.
        highlightRangeMode: root.strip ? GridView.StrictlyEnforceRange : GridView.NoHighlightRange
        preferredHighlightBegin: (root.width - root.thumbWidth) / 2
        preferredHighlightEnd: (root.width - root.thumbWidth) / 2 + view.cellWidth
        highlightMoveDuration: Appearance.anim.scaled(Appearance.anim.normal)
        interactive: root.strip
        clip: root.strip
        reuseItems: true
        keyNavigationWraps: false

        delegate: ClippingRectangle {
            id: thumb

            required property string modelData
            required property int index
            readonly property bool current: root.strip ? thumb.index === view.currentIndex : thumb.modelData === root.selected

            width: root.thumbWidth
            height: root.thumbHeight
            radius: Appearance.rounding.small
            color: Colors.surfaceContainerHigh
            border.width: thumb.current ? Appearance.settings.selectedBorder : 0
            border.color: Colors.primary
            opacity: root.strip && !thumb.current ? Appearance.island.expanded.secondaryOpacity : 1

            Behavior on opacity {
                Anim {}
            }

            Image {
                anchors.fill: parent
                source: `file://${thumb.modelData}`
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                // Decode at thumbnail size; full wallpapers are large.
                sourceSize.width: root.thumbWidth
                sourceSize.height: root.thumbHeight
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

    // One thumbnail per wheel notch or touchpad swipe.
    WheelArea {
        anchors.fill: view
        enabled: root.strip
        horizontal: true
        onStepped: step => root.step(step)
    }
}
