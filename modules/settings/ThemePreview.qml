pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services
import qs.themes

// Colors and style section: built-in presets, wallpaper colors (with a matugen dry-run preview before
// Apply), corner-radius scale, card opacity, and opt-in app templates.
ColumnLayout {
    id: root

    required property string candidate
    required property string scheme
    readonly property var previewPalette: Theme.preview
    // Main roles shown as swatches, with the color they're labelled in.
    readonly property list<string> roles: root.swatchRoles()

    signal schemePicked(string scheme)
    signal applied

    function swatchRoles(): list<string> {
        const roles = ["surfaceContainerHigh", "primary", "primaryContainer"];
        roles.push("secondary", "tertiary", "error");
        return roles;
    }

    spacing: Appearance.settings.gap

    SettingRow {
        label: "Preset palette"
        sublabel: Config.theme.fromWallpaper ? "Picking one turns wallpaper colors off." : `Active: ${Config.theme.preset}`

        Repeater {
            model: Theme.presets

            StyledButton {
                required property string modelData

                text: modelData
                checked: !Config.theme.fromWallpaper && Config.theme.preset === modelData
                onClicked: Theme.setPreset(modelData)
            }
        }
    }

    SettingRow {
        label: "Colors from the wallpaper"
        sublabel: Config.theme.fromWallpaper ? Config.theme.scheme : `Built-in preset (${Config.theme.preset})`

        StyledSwitch {
            checked: Config.theme.fromWallpaper
            onToggled: enabled => Theme.setFromWallpaper(enabled)
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        Repeater {
            model: Theme.schemes

            StyledButton {
                required property string modelData

                text: modelData.replace("scheme-", "")
                checked: modelData === root.scheme
                onClicked: root.schemePicked(modelData)
            }
        }
    }

    // On black, like the island: each swatch with the island text color over it.
    StyledRect {
        Layout.fillWidth: true
        visible: root.previewPalette !== null
        implicitHeight: swatches.implicitHeight + 2 * Appearance.settings.sectionPadding
        radius: Appearance.rounding.normal
        color: Colors.island

        RowLayout {
            id: swatches

            anchors.centerIn: parent
            spacing: Appearance.settings.gap

            Repeater {
                model: root.roles

                ColumnLayout {
                    id: swatch

                    required property string modelData

                    spacing: Appearance.spacing.small

                    StyledRect {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: Appearance.settings.swatch
                        implicitHeight: Appearance.settings.swatch
                        radius: height / 2
                        color: root.previewPalette?.[swatch.modelData] ?? Colors.transparent
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: swatch.modelData.replace("surfaceContainerHigh", "card").replace("Container", " box")
                        color: root.previewPalette?.surfaceFg ?? Colors.surfaceFg
                        font.pixelSize: Appearance.font.size.small
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true

        StyledText {
            Layout.fillWidth: true
            text: root.candidate === "" ? "Pick a wallpaper above to preview its colors." : Theme.error
            elide: Text.ElideRight
            color: Theme.error !== "" ? Colors.error : Colors.surfaceVariantFg
        }

        StyledButton {
            text: "Apply"
            icon: "check"
            filled: true
            enabled: root.candidate !== ""
            onClicked: root.applied()
        }
    }

    SettingRow {
        label: "Corner radius"
        sublabel: "Scales card and panel corners; pills stay round."

        Repeater {
            model: [[0.5, "Sharp"], [1, "Normal"], [1.5, "Round"]]

            StyledButton {
                required property var modelData

                text: modelData[1]
                checked: Math.abs(Config.theme.radiusScale - modelData[0]) < 0.05
                onClicked: Theme.setRadiusScale(modelData[0])
            }
        }
    }

    SettingRow {
        label: "Card opacity"
        sublabel: "Inner cards only; the island and window backgrounds stay pure black."

        Repeater {
            model: [[0.6, "60%"], [0.8, "80%"], [1, "100%"]]

            StyledButton {
                required property var modelData

                text: modelData[1]
                checked: Math.abs(Config.theme.cardOpacity - modelData[0]) < 0.05
                onClicked: Theme.setCardOpacity(modelData[0])
            }
        }
    }

    SettingRow {
        label: "Kitty terminal"
        sublabel: "Writes ~/.local/state/ezshell/kitty-theme.conf and reloads kitty."

        StyledSwitch {
            checked: Config.theme.kitty
            onToggled: enabled => Theme.setKitty(enabled)
        }
    }
}
