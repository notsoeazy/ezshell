import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services
import qs.themes

// Wallpaper and colors. Picking a wallpaper sets it immediately and previews its matugen colors;
// Apply in Colors also enables dynamic colors from the wallpaper.
ColumnLayout {
    id: root

    // The image being previewed, and the scheme chosen for it.
    property string candidate: Config.wallpaper.path
    property string scheme: Config.theme.scheme

    function previewNow(): void {
        if (root.candidate !== "")
            Theme.previewWallpaper(root.candidate, root.scheme);
    }

    spacing: Appearance.settings.padding
    Component.onCompleted: {
        root.previewNow();
        // Opening the page picks up images added since the last scan.
        Wallpapers.rescan();
    }

    Connections {
        function onPathChanged(): void {
            if (Config.wallpaper.path !== "")
                root.candidate = Config.wallpaper.path;
        }

        target: Config.wallpaper
    }

    Section {
        title: "Wallpaper"
        description: "Click a wallpaper to apply it. Leave the path empty to keep another tool's wallpaper."

        SettingRow {
            label: "Folder"

            StyledTextField {
                text: Config.wallpaper.folder
                placeholder: "~/Pictures/Wallpapers"
                onEditingFinished: Config.wallpaper.folder = text.trim()
            }
        }

        StyledText {
            visible: Wallpapers.files.length === 0 && !Wallpapers.scanning
            text: `No images in ${Config.wallpaper.folder}`
            color: Colors.surfaceVariantFg
        }

        WallpaperGrid {
            Layout.fillWidth: true
            paths: Wallpapers.files
            thumbs: Wallpapers.thumbs
            folder: Wallpapers.folder
            selected: root.candidate
            checked: Wallpapers.current
            onVisibleSliceChanged: items => Wallpapers.ensureThumbs(items)
            onPicked: path => {
                root.candidate = path;
                Wallpapers.set(path);
                root.previewNow();
            }
        }

        SettingRow {
            label: "Current"
            sublabel: Config.wallpaper.path !== "" ? Config.wallpaper.path : "None"

            StyledButton {
                text: "Random"
                icon: "shuffle"
                enabled: Wallpapers.files.length > 0
                onClicked: Wallpapers.random()
            }

            StyledButton {
                text: "Clear"
                enabled: Config.wallpaper.path !== ""
                onClicked: Theme.setWallpaper("")
            }
        }

        SettingRow {
            label: "Transition"

            Repeater {
                model: ["fade", "wipe", "none"]

                StyledButton {
                    required property string modelData

                    text: modelData
                    checked: Config.wallpaper.transition === modelData
                    onClicked: Config.wallpaper.transition = modelData
                }
            }
        }

        SettingRow {
            label: "Slideshow"
            sublabel: "Next image in folder order."

            Repeater {
                model: [0, 10, 30, 60]

                StyledButton {
                    required property int modelData

                    text: modelData === 0 ? "off" : modelData < 60 ? `${modelData} min` : `${modelData / 60} h`
                    checked: Config.wallpaper.interval === modelData
                    onClicked: Config.wallpaper.interval = modelData
                }
            }
        }

        SettingRow {
            label: "Fill"
            sublabel: "Crop fills, fit shows it all, center is actual size."

            Repeater {
                model: ["crop", "fit", "center"]

                StyledButton {
                    required property string modelData

                    text: modelData
                    checked: Config.wallpaper.fill === modelData
                    onClicked: Config.wallpaper.fill = modelData
                }
            }
        }
    }

    Section {
        title: "Colors & Style"
        description: "Generated from the wallpaper with matugen, or from a built-in dark preset (the island is black)."

        ThemePreview {
            Layout.fillWidth: true
            candidate: root.candidate
            scheme: root.scheme
            onSchemePicked: scheme => {
                root.scheme = scheme;
                root.previewNow();
            }
            onApplied: {
                Theme.setScheme(root.scheme);
                Theme.setWallpaper(root.candidate);
                Theme.setFromWallpaper(true);
            }
        }
    }
}
