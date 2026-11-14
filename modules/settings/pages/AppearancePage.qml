pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.components
import qs.components.containers
import qs.components.controls
import qs.modules.settings

SettingsPage {
    id: root

    // The palette styles offered here; the config file takes any of
    // matugen's.
    readonly property list<var> variants: [
        {
            name: "tonal-spot",
            title: "Calm"
        },
        {
            name: "neutral",
            title: "Muted"
        },
        {
            name: "vibrant",
            title: "Vivid"
        },
        {
            name: "expressive",
            title: "Playful"
        }
    ]

    Group {
        Layout.fillWidth: true
        title: "Theme"

        ListRow {
            Layout.fillWidth: true
            title: "Dark mode"
            icon: "dark_mode"
            interactive: false

            Switch {
                checked: Config.appearance.dark
                onToggled: Config.appearance.dark = !Config.appearance.dark
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Accent colour"
            subtitle: Theme.dynamic ? "Taken from the wallpaper" : ""
            icon: "colors"
            interactive: false
            separator: false
            disabled: Theme.dynamic

            Repeater {
                model: Theme.accentNames

                // A dot of the colour; the one in use has a ring.
                Rectangle {
                    id: dot

                    required property string modelData
                    readonly property bool selected: Config.appearance.accent === modelData

                    implicitWidth: Tokens.control.sm
                    implicitHeight: Tokens.control.sm
                    radius: height / 2
                    color: Theme.color[modelData]
                    border.width: selected ? Tokens.state.focusRing : 0
                    border.color: Theme.color.label

                    Pressable {
                        radius: dot.radius
                        onActivated: Config.appearance.accent = dot.modelData
                    }
                }
            }
        }
    }

    Group {
        Layout.fillWidth: true
        title: "Colours from the wallpaper"
        note: "A Material palette is made from the wallpaper with matugen. Turn it off for the fixed colours and your own accent."

        ListRow {
            Layout.fillWidth: true
            title: "Use the wallpaper's colours"
            icon: "palette"
            interactive: false

            Switch {
                checked: Config.theming.dynamic
                onToggled: Config.theming.dynamic = !Config.theming.dynamic
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Style"
            subtitle: "How colourful the palette is"
            icon: "tune"
            interactive: false
            separator: false
            disabled: !Config.theming.dynamic

            SegmentedControl {
                segments: root.variants.map(variant => variant.title)
                current: root.variants.findIndex(variant => variant.name === Config.theming.variant)
                onSelected: index => Config.theming.variant = root.variants[index].name
            }
        }
    }

    Group {
        Layout.fillWidth: true
        title: "Colour other programs"
        note: "Each of these writes outside the shell, and only while the wallpaper's colours are in use. GTK programs pick the colours up when they next start."

        ListRow {
            Layout.fillWidth: true
            title: "Terminals"
            subtitle: "Open terminals at once; new ones from sequences.txt"
            icon: "terminal"
            interactive: false
            disabled: !Config.theming.dynamic

            Switch {
                checked: Config.theming.terminal
                onToggled: Config.theming.terminal = !Config.theming.terminal
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Hyprland"
            subtitle: "Writes ~/.config/hypr/scheme/current.lua"
            icon: "web_asset"
            interactive: false
            disabled: !Config.theming.dynamic

            Switch {
                checked: Config.theming.hyprland
                onToggled: Config.theming.hyprland = !Config.theming.hyprland
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "GTK programs"
            subtitle: "Writes gtk.css in ~/.config/gtk-3.0 and gtk-4.0"
            icon: "widgets"
            interactive: false
            disabled: !Config.theming.dynamic

            Switch {
                checked: Config.theming.gtk
                onToggled: Config.theming.gtk = !Config.theming.gtk
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Your templates"
            subtitle: "Fills in each file in ~/.config/ezshell/templates"
            icon: "description"
            interactive: false
            separator: false
            disabled: !Config.theming.dynamic

            Switch {
                checked: Config.theming.templates
                onToggled: Config.theming.templates = !Config.theming.templates
            }
        }
    }

    Group {
        Layout.fillWidth: true
        title: "Screen border"
        note: "A frame around the screen edge in the island's colour. The island hangs from its top. A thickness of 0 turns it off."

        ListRow {
            Layout.fillWidth: true
            title: "Thickness"
            icon: "border_outer"
            interactive: false

            Stepper {
                value: Config.border.thickness
                from: 0
                to: 24
                step: 1
                text: `${Config.border.thickness} px`
                onMoved: value => Config.border.thickness = value
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Corner rounding"
            icon: "rounded_corner"
            interactive: false
            separator: false

            Stepper {
                value: Config.border.rounding
                from: 0
                to: 48
                step: 2
                text: `${Config.border.rounding} px`
                onMoved: value => Config.border.rounding = value
            }
        }
    }

    Group {
        Layout.fillWidth: true
        title: "Motion"
        note: "Reduce motion removes the bounce and shortens movement. Animation length stretches or shrinks every animation."

        ListRow {
            Layout.fillWidth: true
            title: "Reduce motion"
            icon: "animation"
            interactive: false

            Switch {
                checked: Config.appearance.reduceMotion
                onToggled: Config.appearance.reduceMotion = !Config.appearance.reduceMotion
            }
        }

        ListRow {
            Layout.fillWidth: true
            title: "Animation length"
            icon: "speed"
            interactive: false
            separator: false

            Stepper {
                value: Config.appearance.animationScale
                from: 0.25
                to: 5
                step: 0.25
                text: `${Math.round(Config.appearance.animationScale * 100)}%`
                onMoved: value => Config.appearance.animationScale = value
            }
        }
    }
}
