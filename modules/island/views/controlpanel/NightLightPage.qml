import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.components.controls
import qs.services

// Night light: on or off, and how warm.
PanelPage {
    title: "Night Light"

    accessory: Switch {
        checked: NightLight.enabled
        onToggled: NightLight.setEnabled(!NightLight.enabled)
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.sm

        Icon {
            name: "local_fire_department"
            level: Icon.Secondary
        }

        // Warmer to the left: a lower temperature.
        Slider {
            Layout.fillWidth: true
            from: NightLight.warmest
            to: NightLight.coolest
            value: NightLight.temperature
            onMoved: value => NightLight.setTemperature(value)
        }

        Icon {
            name: "ac_unit"
            level: Icon.Secondary
        }

        Label {
            Layout.preferredWidth: Tokens.spacing.xxxl * 2
            text: `${NightLight.temperature} K`
            horizontalAlignment: Text.AlignRight
            tabular: true
            level: Label.Secondary
        }
    }

    Label {
        Layout.fillWidth: true
        text: "Warmer colours are easier on the eyes at night."
        fontSize: Tokens.fontSize.sm
        level: Label.Tertiary
    }
}
