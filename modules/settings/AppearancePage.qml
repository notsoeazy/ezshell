import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services
import qs.themes

// Wallpaper and colors. Picking a wallpaper or a scheme only previews; Apply sets the wallpaper and
// turns wallpaper colors on, and the Theme service regenerates theme.json.
ColumnLayout {
    id: root

    // The image being previewed (not applied yet), and the scheme chosen for it.
    property string candidate: Config.wallpaper.path
    property string scheme: Config.theme.scheme

    function previewNow(): void {
        if (root.candidate !== "")
            Theme.previewWallpaper(root.candidate, root.scheme);
    }

    spacing: Appearance.settings.padding
    Component.onCompleted: root.previewNow()

    Section {
        title: "Wallpaper"
        description: "Leave the path empty to keep another tool's wallpaper."

        SettingRow {
            label: "Folder"

            StyledTextField {
                text: Config.wallpaper.folder
                placeholder: "~/Pictures/Wallpapers"
                onEditingFinished: Config.wallpaper.folder = text.trim()
            }
        }

        WallpaperPicker {
            Layout.fillWidth: true
            selected: root.candidate
            onPicked: path => {
                root.candidate = path;
                root.previewNow();
            }
        }

        SettingRow {
            label: "Current"
            sublabel: Config.wallpaper.path !== "" ? Config.wallpaper.path : "None"

            StyledButton {
                text: "Clear"
                enabled: Config.wallpaper.path !== ""
                onClicked: Theme.setWallpaper("")
            }
        }
    }

    Section {
        title: "Colors"
        description: "Generated from the wallpaper with matugen, always the dark variant (the island is black)."

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
