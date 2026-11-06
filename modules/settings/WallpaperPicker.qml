pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell.Widgets
import qs.components
import qs.config
import qs.themes

// Thumbnails of the images in Config.wallpaper.folder. Picking one only reports it; the page decides.
ColumnLayout {
    id: root

    required property string selected

    signal picked(string path)

    spacing: Appearance.settings.gap

    FolderListModel {
        id: images

        folder: `file://${Paths.expand(Config.wallpaper.folder)}`
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        showDirs: false
    }

    StyledText {
        visible: images.count === 0
        text: `No images in ${Config.wallpaper.folder}`
        color: Colors.surfaceVariantFg
    }

    Flow {
        Layout.fillWidth: true
        spacing: Appearance.settings.gap

        Repeater {
            model: images

            ClippingRectangle {
                id: thumb

                required property string filePath
                readonly property bool current: thumb.filePath === root.selected

                implicitWidth: Appearance.settings.thumbWidth
                implicitHeight: Appearance.settings.thumbHeight
                radius: Appearance.rounding.small
                color: Colors.surfaceContainerHigh
                border.width: thumb.current ? Appearance.settings.selectedBorder : 0
                border.color: Colors.primary

                Image {
                    anchors.fill: parent
                    source: `file://${thumb.filePath}`
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    // Decode at thumbnail size; full wallpapers are large.
                    sourceSize.width: Appearance.settings.thumbWidth
                    sourceSize.height: Appearance.settings.thumbHeight
                }

                TapHandler {
                    onTapped: root.picked(thumb.filePath)
                }
            }
        }
    }
}
