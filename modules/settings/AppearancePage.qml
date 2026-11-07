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

    function nextChangeText(): string {
        if (NightLight.schedule === "off")
            return "Off: only manual changes";
        const next = NightLight.nextChange;
        if (!next)
            return NightLight.schedule === "sun" ? "Waiting for the weather location" : "Check the times";
        return `Next change at ${Qt.formatTime(next, "HH:mm")}${NightLight.enabled ? " (off)" : " (on)"}`;
    }

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

        StyledText {
            visible: Wallpapers.files.length === 0 && !Wallpapers.scanning
            text: `No images in ${Config.wallpaper.folder}`
            color: Colors.surfaceVariantFg
        }

        WallpaperGrid {
            Layout.fillWidth: true
            paths: Wallpapers.files
            folder: Wallpapers.folder
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

    Section {
        title: "Night light"
        description: "Warms the screen through hyprsunset. A manual change holds until the next scheduled one."

        SettingRow {
            label: "Night light"
            sublabel: NightLight.enabled ? `On, ${NightLight.temperature} K` : "Off"

            StyledSwitch {
                checked: NightLight.enabled
                onToggled: checked => NightLight.set(checked)
            }
        }

        SettingRow {
            label: "Schedule"
            sublabel: root.nextChangeText()

            Repeater {
                model: [["off", "Off"], ["fixed", "Fixed times"], ["sun", "Sunset to sunrise"]]

                StyledButton {
                    required property var modelData

                    text: modelData[1]
                    checked: NightLight.schedule === modelData[0]
                    onClicked: NightLight.setSchedule(modelData[0])
                }
            }
        }

        SettingRow {
            visible: NightLight.schedule === "fixed"
            label: "From and to"
            sublabel: "24-hour, e.g. 20:00 and 07:00"

            StyledTextField {
                id: start

                implicitWidth: Appearance.control.numberWidth
                text: Config.nightLight.start
                placeholder: "20:00"
                onEditingFinished: NightLight.setTimes(start.text, end.text)
            }

            StyledTextField {
                id: end

                implicitWidth: Appearance.control.numberWidth
                text: Config.nightLight.end
                placeholder: "07:00"
                onEditingFinished: NightLight.setTimes(start.text, end.text)
            }
        }
    }
}
