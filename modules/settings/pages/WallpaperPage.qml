import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.island
import qs.modules.settings

SettingsPage {
    Group {
        Layout.fillWidth: true
        title: "Wallpaper"
        note: `${Wallpapers.list.length} pictures found. Turn drawing off if another tool sets your wallpaper.`

        ListRow {
            Layout.fillWidth: true
            title: "Draw the wallpaper"
            icon: "wallpaper"
            interactive: false

            Switch {
                checked: Config.wallpaper.enabled
                onToggled: Config.wallpaper.enabled = !Config.wallpaper.enabled
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Current"
            subtitle: Wallpapers.current.length > 0 ? Wallpapers.name(Wallpapers.current) : "None"
            icon: "image"
            interactive: false

            Button {
                text: "Choose…"
                capsule: true
                disabled: Wallpapers.list.length === 0
                onActivated: IslandState.open("wallpaper")
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Folder"
            subtitle: "Searched three levels deep; ~ is your home"
            icon: "folder"
            interactive: false
            separator: false

            Field {
                value: Config.wallpaper.directory
                onCommitted: text => Config.wallpaper.directory = text
            }
        }
    }
}
