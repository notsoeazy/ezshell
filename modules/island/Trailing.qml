import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.state
import qs.themes
import qs.utils

// Indicators (Indicators.qml), then status icons in ISLAND.md order: wifi, bluetooth, volume, battery.
RowLayout {
    id: root

    required property string screenName

    // Space priority (docs/ISLAND.md): Default.qml sets these when the island would pass its max width.
    property bool compactBadge: false
    property bool compactBattery: false
    readonly property bool batteryLabel: Battery.charging || Battery.low
    readonly property real badgeSaving: indicators.badgeSaving
    readonly property real batterySaving: root.batteryLabel ? percent.implicitWidth + Appearance.spacing.small : 0
    // Width with nothing compacted, so Default can decide without a binding loop.
    readonly property real badgeRemoved: root.compactBadge ? root.badgeSaving : 0
    readonly property real removed: root.badgeRemoved + (root.compactBattery ? root.batterySaving : 0)
    readonly property real naturalWidth: root.implicitWidth + root.removed
    readonly property color dischargingColor: Battery.low ? Colors.error : Colors.surfaceFg
    readonly property color batteryColor: Battery.charging ? Colors.success : root.dischargingColor

    function open(section: string): void {
        Visibility.openByPointer(section, root.screenName);
    }

    spacing: Appearance.spacing.normal

    Indicators {
        id: indicators

        screenName: root.screenName
        compactBadge: root.compactBadge
    }

    MaterialIcon {
        visible: Wifi.device !== null
        text: Icons.wifi(Wifi.enabled, Wifi.connected, Wifi.strength)

        // Exclusive grab on press, so the island's background TapHandler doesn't also fire.
        TapHandler {
            margin: Appearance.spacing.small
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: root.open("wifi")
        }
    }

    MaterialIcon {
        visible: Bt.available
        text: Icons.bluetooth(Bt.enabled, Bt.connected.length > 0)

        // Exclusive grab on press, so the island's background TapHandler doesn't also fire.
        TapHandler {
            margin: Appearance.spacing.small
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: root.open("bluetooth")
        }
    }

    MaterialIcon {
        text: Icons.volume(Audio.volume, Audio.muted)

        // Exclusive grab on press, so the island's background TapHandler doesn't also fire.
        TapHandler {
            margin: Appearance.spacing.small
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: root.open("audio")
        }

        WheelArea {
            anchors.fill: parent
            anchors.margins: -Appearance.spacing.small
            onStepped: step => step < 0 ? Audio.up() : Audio.down()
        }
    }

    RowLayout {
        visible: Battery.available
        spacing: Appearance.spacing.small

        // Exclusive grab on press, so the island's background TapHandler doesn't also fire.
        TapHandler {
            margin: Appearance.spacing.small
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: root.open("power")
        }

        MaterialIcon {
            text: Icons.battery(Battery.level, Battery.charging, Battery.low, Battery.full)
            color: root.batteryColor
        }

        StyledText {
            id: percent

            opacity: (root.batteryLabel && !root.compactBattery) ? 1 : 0
            // Fades out before leaving the layout, so the balance-rule width change follows the fade.
            visible: opacity > 0

            Behavior on opacity {
                Anim {}
            }
            text: `${Math.round(Battery.level * 100)}%`
            color: root.batteryColor
            font.weight: Font.Medium
        }
    }
}
