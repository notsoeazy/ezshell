import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components
import qs.services
import qs.themes

// After a screenshot: its thumbnail and "Saved · Copied". The notification with Open, Open folder and
// Edit goes to the list.
RowLayout {
    spacing: Appearance.island.capture.padding

    // Pops in, so a screenshot reads as taken even before the text does.
    ClippingRectangle {
        id: thumb

        scale: Appearance.island.capture.popFrom
        Component.onCompleted: thumb.scale = 1
        implicitWidth: Appearance.island.capture.thumbWidth
        implicitHeight: Appearance.island.capture.thumbHeight
        radius: Appearance.rounding.small
        color: Colors.surfaceContainerHigh

        Behavior on scale {
            Anim {
                duration: Appearance.anim.scaled(Appearance.anim.islandExpand)
                easing.type: Easing.OutBack
            }
        }

        Image {
            anchors.fill: parent
            source: Capture.lastShot !== "" ? `file://${Capture.lastShot}` : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: Appearance.island.capture.thumbWidth
            sourceSize.height: Appearance.island.capture.thumbHeight
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        StyledText {
            Layout.fillWidth: true
            text: "Screenshot"
            font.weight: Font.DemiBold
        }

        StyledText {
            Layout.fillWidth: true
            text: "Saved · Copied"
            color: Colors.surfaceVariantFg
            font.pixelSize: Appearance.font.size.small
        }
    }
}
