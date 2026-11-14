import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.containers
import qs.components.controls
import qs.modules.settings

SettingsPage {
    Group {
        Layout.fillWidth: true
        title: "Modes"
        note: "Start a search with one of these to switch mode. Anything else searches apps."

        ListRow {
            Layout.fillWidth: true
            title: "Actions"
            icon: "bolt"
            interactive: false

            Field {
                implicitWidth: Tokens.spacing.xxxl * 2
                value: Config.launcher.actionsPrefix
                onCommitted: text => Config.launcher.actionsPrefix = text
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Clipboard history"
            icon: "content_paste"
            interactive: false

            Field {
                implicitWidth: Tokens.spacing.xxxl * 2
                value: Config.launcher.clipboardPrefix
                onCommitted: text => Config.launcher.clipboardPrefix = text
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Emoji and symbols"
            icon: "emoji_symbols"
            interactive: false
            separator: false

            Field {
                implicitWidth: Tokens.spacing.xxxl * 2
                value: Config.launcher.symbolsPrefix
                onCommitted: text => Config.launcher.symbolsPrefix = text
            }
        }
    }

    Group {
        Layout.fillWidth: true
        title: "Results"

        ListRow {
            Layout.fillWidth: true
            title: "Show at most"
            icon: "format_list_numbered"
            interactive: false
            separator: false

            Stepper {
                value: Config.launcher.maxResults
                from: 10
                to: 200
                step: 10
                onMoved: value => Config.launcher.maxResults = value
            }
        }
    }
}
