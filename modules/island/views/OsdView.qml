import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.island

// The on-screen display: a level bar for volume and brightness, or a short
// message. It shows over fullscreen windows, stays while the pointer is on
// it, and a level can be dragged or scrolled.
View {
    showOverFullscreen: true
    holdOnHover: true

    // Never shorter than the island at rest, whatever it is showing; the row
    // is centred in it.
    Item {
        implicitWidth: row.implicitWidth
        implicitHeight: Math.max(row.implicitHeight, Tokens.island.height - Tokens.island.paddingY * 2)

        RowLayout {
            id: row

            anchors.centerIn: parent
            spacing: Tokens.spacing.sm

            LevelSlider {
                implicitWidth: Tokens.spacing.xxxl * 7
                visible: Osd.kind === "level"
                size: Tokens.size.md
                icon: Osd.icon
                value: Osd.value
                // A level with no source is only shown, not changed.
                interactive: Osd.source.length > 0
                onMoved: value => Osd.adjust(value)
            }

            // A message gets more room at the sides than the island's usual
            // padding: its shoulders take up the corners, so the content looks
            // closer to the edge than it is.
            Icon {
                Layout.leftMargin: Tokens.spacing.sm
                visible: Osd.kind === "toast"
                name: Osd.icon.length > 0 ? Osd.icon : "info"
                size: Tokens.icon.sm
            }

            Label {
                Layout.rightMargin: Tokens.spacing.sm
                visible: Osd.kind === "toast"
                text: Osd.text
                emphasized: true
            }
        }
    }
}
