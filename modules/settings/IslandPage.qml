pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.themes

// Island customization: workspace paging, 3-part layout spacing, clock/date behavior, and icon visibility.
ColumnLayout {
    id: root

    readonly property int maxCornerRadius: 28
    readonly property int maxSectionGap: 48
    readonly property int minSidePadding: 6
    readonly property int maxSidePadding: 36
    readonly property int minItemSpacing: 4
    readonly property int maxItemSpacing: 20
    readonly property int maxTopMargin: 24

    function setShown(value: int): void {
        Config.workspaces.shown = Math.max(1, Math.min(20, value));
    }

    function lerpInt(min: int, max: int, value: real): int {
        return Math.round(min + value * (max - min));
    }

    function dateSublabel(): string {
        if (!Config.island.showDate)
            return "Hidden";
        return Config.island.showDateOnHover ? "Shown underneath the clock on hover" : "Shown inline next to the clock";
    }

    function resetLayout(): void {
        Config.island.balancedWings = true;
        Config.island.cornerRadius = 22;
        Config.island.sectionGap = 8;
        Config.island.sidePadding = 14;
        Config.island.itemSpacing = 8;
        Config.island.topMargin = 6;
    }

    spacing: Appearance.settings.padding

    Section {
        title: "Workspaces"
        description: "Workspaces per page on the island. Moving past the last slot flips to the next page."

        SettingRow {
            label: "Show workspaces"
            sublabel: "Display workspace indicator on the left side of the island"

            StyledSwitch {
                checked: Config.island.showWorkspaces
                onToggled: checked => Config.island.showWorkspaces = checked
            }
        }

        SettingRow {
            label: "Shown per page"
            sublabel: `${Config.workspaces.shown} workspaces per page`

            Repeater {
                model: [5, 8, 10]

                StyledButton {
                    required property int modelData

                    text: `${modelData}`
                    checked: Config.workspaces.shown === modelData
                    onClicked: root.setShown(modelData)
                }
            }

            StyledButton {
                icon: "remove"
                enabled: Config.workspaces.shown > 1
                onClicked: root.setShown(Config.workspaces.shown - 1)
            }

            PxField {
                value: Config.workspaces.shown
                min: 1
                max: 20
                onCommitted: value => root.setShown(value)
            }

            StyledButton {
                icon: "add"
                enabled: Config.workspaces.shown < 20
                onClicked: root.setShown(Config.workspaces.shown + 1)
            }
        }

        SettingRow {
            label: "Workspace numbers"
            sublabel: "Show workspace numbers inside the indicator dots"

            StyledSwitch {
                checked: Config.workspaces.showNumbers
                onToggled: checked => Config.workspaces.showNumbers = checked
            }
        }
    }

    Section {
        title: "Layout & Spacing"
        description: "Adjust wing balance and the distance between the left wing, center clock, and right wing."

        SettingRow {
            label: "Balanced wings"
            sublabel: Config.island.balancedWings ? "Equal wing widths center the clock" : "Wings fit their own content"

            StyledSwitch {
                checked: Config.island.balancedWings
                onToggled: checked => Config.island.balancedWings = checked
            }
        }

        SettingRow {
            label: "Island corner radius"
            sublabel: `${Config.island.cornerRadius} px (22+ = full pill at rest)`

            StyledSlider {
                value: Config.island.cornerRadius / root.maxCornerRadius
                onMoved: value => Config.island.cornerRadius = Math.round(value * root.maxCornerRadius)
            }

            PxField {
                value: Config.island.cornerRadius
                min: 0
                max: root.maxCornerRadius
                onCommitted: value => Config.island.cornerRadius = value
            }
        }

        SettingRow {
            label: "Center gap"
            sublabel: `${Config.island.sectionGap} px between wings and the center clock`

            StyledSlider {
                value: Config.island.sectionGap / root.maxSectionGap
                onMoved: value => Config.island.sectionGap = Math.round(value * root.maxSectionGap)
            }

            PxField {
                value: Config.island.sectionGap
                min: 0
                max: root.maxSectionGap
                onCommitted: value => Config.island.sectionGap = value
            }
        }

        SettingRow {
            label: "Outer horizontal padding"
            sublabel: `${Config.island.sidePadding} px at the left and right edges`

            StyledSlider {
                value: (Config.island.sidePadding - root.minSidePadding) / (root.maxSidePadding - root.minSidePadding)
                onMoved: v => Config.island.sidePadding = root.lerpInt(root.minSidePadding, root.maxSidePadding, v)
            }

            PxField {
                value: Config.island.sidePadding
                min: root.minSidePadding
                max: root.maxSidePadding
                onCommitted: value => Config.island.sidePadding = value
            }
        }

        SettingRow {
            label: "Wing item spacing"
            sublabel: `${Config.island.itemSpacing} px between icons inside each wing`

            StyledSlider {
                value: (Config.island.itemSpacing - root.minItemSpacing) / (root.maxItemSpacing - root.minItemSpacing)
                onMoved: v => Config.island.itemSpacing = root.lerpInt(root.minItemSpacing, root.maxItemSpacing, v)
            }

            PxField {
                value: Config.island.itemSpacing
                min: root.minItemSpacing
                max: root.maxItemSpacing
                onCommitted: value => Config.island.itemSpacing = value
            }
        }

        SettingRow {
            label: "Top screen margin"
            sublabel: `${Config.island.topMargin} px from the top screen edge`

            StyledSlider {
                value: Config.island.topMargin / root.maxTopMargin
                onMoved: value => Config.island.topMargin = Math.round(value * root.maxTopMargin)
            }

            PxField {
                value: Config.island.topMargin
                min: 0
                max: root.maxTopMargin
                onCommitted: value => Config.island.topMargin = value
            }
        }

        SettingRow {
            label: "Reset spacing"
            sublabel: "Restore default wing balance, gap, padding, and margin"

            StyledButton {
                text: "Reset"
                icon: "restart_alt"
                onClicked: root.resetLayout()
            }
        }
    }

    Section {
        title: "Clock & Hover"
        description: "Control how the clock, date, and hover peek behave on the resting island."

        SettingRow {
            label: "24-hour clock"
            sublabel: Config.bar.use24Hour ? "13:00" : "1:00 PM"

            StyledSwitch {
                checked: Config.bar.use24Hour
                onToggled: checked => Config.bar.use24Hour = checked
            }
        }

        SettingRow {
            label: "Show seconds"

            StyledSwitch {
                checked: Config.bar.showSeconds
                onToggled: checked => Config.bar.showSeconds = checked
            }
        }

        SettingRow {
            label: "Date display"
            sublabel: root.dateSublabel()

            StyledButton {
                text: "On hover"
                checked: Config.island.showDate && Config.island.showDateOnHover
                onClicked: {
                    Config.island.showDate = true;
                    Config.island.showDateOnHover = true;
                }
            }

            StyledButton {
                text: "Always inline"
                checked: Config.island.showDate && !Config.island.showDateOnHover
                onClicked: {
                    Config.island.showDate = true;
                    Config.island.showDateOnHover = false;
                }
            }

            StyledButton {
                text: "Hidden"
                checked: !Config.island.showDate
                onClicked: Config.island.showDate = false
            }
        }

        SettingRow {
            label: "Hover peek"
            sublabel: "Expand the island on pointer hover to show date, active app, media, and notifications"

            StyledSwitch {
                checked: Config.island.hoverPeek
                onToggled: checked => Config.island.hoverPeek = checked
            }
        }
    }

    Section {
        title: "Icons & Indicators"
        description: "Choose which widgets, tray icons, and status icons appear on the resting island."

        SettingRow {
            label: "System tray"
            sublabel: "Background app icons on the left wing"

            StyledSwitch {
                checked: Config.island.showTray
                onToggled: checked => Config.island.showTray = checked
            }
        }

        SettingRow {
            label: "Music equalizer"
            sublabel: "Animated bars when media is playing"

            StyledSwitch {
                checked: Config.island.showEqualizer
                onToggled: checked => Config.island.showEqualizer = checked
            }
        }

        SettingRow {
            label: "Wi‑Fi icon"

            StyledSwitch {
                checked: Config.island.showWifi
                onToggled: checked => Config.island.showWifi = checked
            }
        }

        SettingRow {
            label: "Bluetooth icon"

            StyledSwitch {
                checked: Config.island.showBluetooth
                onToggled: checked => Config.island.showBluetooth = checked
            }
        }

        SettingRow {
            label: "Volume icon"

            StyledSwitch {
                checked: Config.island.showVolume
                onToggled: checked => Config.island.showVolume = checked
            }
        }

        SettingRow {
            label: "Battery icon"

            StyledSwitch {
                checked: Config.island.showBattery
                onToggled: checked => Config.island.showBattery = checked
            }
        }

        SettingRow {
            label: "Notification & DND indicator"

            StyledSwitch {
                checked: Config.island.showNotifDot
                onToggled: checked => Config.island.showNotifDot = checked
            }
        }

        SettingRow {
            label: "Privacy indicator"
            sublabel: "Microphone and camera in-use dot"

            StyledSwitch {
                checked: Config.island.showPrivacy
                onToggled: checked => Config.island.showPrivacy = checked
            }
        }

        SettingRow {
            label: "Recording & screen share indicator"

            StyledSwitch {
                checked: Config.island.showRecord
                onToggled: checked => Config.island.showRecord = checked
            }
        }
    }

    component PxField: StyledTextField {
        id: field

        required property int value
        required property int min
        required property int max

        signal committed(int value)

        implicitWidth: Appearance.control.numberWidth
        text: `${field.value}`
        validator: IntValidator {
            bottom: field.min
            top: field.max
        }
        onEditingFinished: {
            const parsed = parseInt(field.text);
            if (!isNaN(parsed))
                field.committed(Math.max(field.min, Math.min(field.max, parsed)));
            field.text = Qt.binding(() => `${field.value}`);
        }
    }
}
