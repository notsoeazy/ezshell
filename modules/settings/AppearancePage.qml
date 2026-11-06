import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components
import qs.config
import qs.themes

ColumnLayout {
    id: root

    spacing: Appearance.settings.padding

    Section {
        title: "Wallpaper"
        description: "Leave empty to keep another tool's wallpaper. Wallpaper-based colors come later."

        SettingRow {
            label: "Image path"

            StyledTextField {
                id: path

                text: Config.wallpaper.path
                placeholder: "~/Pictures/wallpaper.png"
                onEditingFinished: Config.wallpaper.path = Paths.expand(path.text.trim())
            }

            StyledButton {
                text: "Clear"
                enabled: Config.wallpaper.path !== ""
                onClicked: Config.wallpaper.path = ""
            }
        }

        ClippingRectangle {
            visible: Config.wallpaper.path !== ""
            implicitWidth: Appearance.settings.previewWidth
            implicitHeight: Appearance.settings.previewHeight
            radius: Appearance.rounding.small
            color: Colors.surfaceContainerHigh

            Image {
                anchors.fill: parent
                source: Config.wallpaper.path !== "" ? `file://${Config.wallpaper.path}` : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: Appearance.settings.previewWidth
                sourceSize.height: Appearance.settings.previewHeight
            }
        }
    }
}
