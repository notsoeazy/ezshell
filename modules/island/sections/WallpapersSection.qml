pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.state
import qs.themes

// Wallpapers section: search, a grid of the folder (subfolders included) and the selected name.
// A single row with the selection centered: arrows or scrolling slide it, Enter or a click on the
// centered image applies and collapses the island; Esc collapses (Expanded.qml).
ColumnLayout {
    id: root

    readonly property int gap: Appearance.island.expanded.gap

    function apply(path: string): void {
        if (path === "")
            return;
        Wallpapers.set(path);
        Visibility.close();
    }

    function handleKey(event: KeyEvent): void {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            root.apply(grid.currentPath);
        else if (!grid.navigate(event.key))
            return;
        event.accepted = true;
    }

    spacing: root.gap
    // Back from under the polkit prompt: the search field takes the keyboard again.
    onVisibleChanged: {
        if (visible)
            search.focusInput();
    }
    Component.onCompleted: {
        // Picks up images added since the last scan; the list keeps showing meanwhile.
        Wallpapers.rescan();
        search.focusInput();
    }

    StyledTextField {
        id: search

        Layout.fillWidth: true
        placeholder: Wallpapers.files.length === 1 ? "Search 1 wallpaper" : `Search ${Wallpapers.files.length} wallpapers`
        onKeyPressed: event => root.handleKey(event)
    }

    WallpaperGrid {
        id: grid

        Layout.fillWidth: true
        paths: Wallpapers.files
        thumbs: Wallpapers.thumbs
        folder: Wallpapers.folder
        filter: search.text
        selected: grid.currentPath
        checked: Wallpapers.current
        thumbWidth: Appearance.island.wallpapers.thumbWidth
        thumbHeight: Appearance.island.wallpapers.thumbHeight
        gap: root.gap
        strip: true
        // A new list or filter starts on the wallpaper in use when it's among the results.
        onShownChanged: grid.currentIndex = Math.max(0, grid.shown.indexOf(Wallpapers.current))
        onPicked: path => root.apply(path)

        StyledText {
            anchors.centerIn: parent
            visible: grid.count === 0 && !Wallpapers.scanning
            text: Wallpapers.files.length === 0 ? `No images in ${Wallpapers.folder}` : "No matches"
            color: Colors.surfaceVariantFg
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: grid.relative(grid.currentPath)
            elide: Text.ElideMiddle
        }

        StyledText {
            text: "←→ or scroll   ↵ apply   esc close"
            color: Colors.surfaceVariantFg
            font.pixelSize: Appearance.font.size.small
        }
    }
}
