import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services
import qs.state
import qs.themes

RowLayout {
    id: root

    required property string screenName
    readonly property string special: Hypr.activeSpecial(root.screenName)
    // Raw config JSON entry; null for special workspaces that aren't in the config.
    readonly property var entry: Config.workspaces.special.find(w => w.name === root.special) ?? null
    // Space priority (docs/ISLAND.md): Default.qml drops the chip's name when the island is too wide.
    property bool compactSpecial: false
    readonly property real specialSaving: root.special ? specialName.implicitWidth + Appearance.spacing.small : 0
    // Width with nothing compacted, so Default can decide without a binding loop.
    readonly property real naturalWidth: root.implicitWidth + (root.compactSpecial ? root.specialSaving : 0)

    spacing: Appearance.spacing.normal

    // The chip covers the workspace indicator in place, so the slot takes whichever is showing.
    Item {
        implicitWidth: root.special ? chip.implicitWidth : workspaces.implicitWidth
        implicitHeight: Appearance.island.chipHeight

        Workspaces {
            id: workspaces

            screenName: root.screenName
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.special ? 0 : 1
            visible: opacity > 0

            Behavior on opacity {
                Anim {}
            }
        }

        WheelArea {
            anchors.fill: parent
            enabled: !root.special
            onStepped: step => Hypr.cycle(root.screenName, step)
        }

        StyledRect {
            id: chip

            implicitWidth: label.implicitWidth + 2 * Appearance.island.chipPadding
            implicitHeight: Appearance.island.chipHeight
            anchors.verticalCenter: parent.verticalCenter
            radius: height / 2
            color: Colors.tertiaryContainer
            opacity: root.special ? 1 : 0
            visible: opacity > 0

            // Toggles (hides) the open special workspace; no expand.
            TapHandler {
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: Hypr.toggleSpecial(root.special)
            }

            Behavior on opacity {
                Anim {}
            }

            RowLayout {
                id: label

                anchors.centerIn: parent
                spacing: Appearance.spacing.small

                MaterialIcon {
                    text: root.entry?.icon ?? "layers"
                    fill: 1
                    color: Colors.tertiaryContainerFg
                }

                StyledText {
                    id: specialName

                    visible: !root.compactSpecial
                    text: root.special
                    color: Colors.tertiaryContainerFg
                    font.weight: Font.Medium
                }
            }
        }
    }

    Equalizer {
        opacity: (Players.active !== null && Players.title !== "") ? 1 : 0
        // Fades out before leaving the layout, so the balance-rule width change follows the fade.
        visible: opacity > 0

        Behavior on opacity {
            Anim {}
        }

        TapHandler {
            margin: Appearance.spacing.small
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: Visibility.openByPointer("media", root.screenName)
        }

        playing: Players.playing
        tint: Players.playing ? (Players.hasAccent ? Players.accent : Colors.primary) : Colors.surfaceVariantFg
    }

    TrayWidget {}
}
