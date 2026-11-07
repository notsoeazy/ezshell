import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components
import qs.themes

// A Control-tab level chip: the chip is the slider. Its fill shows the level; pressing or dragging sets it,
// the wheel steps it, and the owner writes the value back from `moved`. The icon reports `iconClicked`
// (mute), and right-click reports `opened` (the detail section).
ClippingRectangle {
    id: root

    property string label: ""
    property string status: ""
    property string icon: ""
    property real value: 0
    // Change per wheel notch.
    property real step: 0.05

    signal moved(real value)
    signal iconClicked
    signal opened

    function valueAt(x: real): real {
        return Math.max(0, Math.min(1, x / root.width));
    }

    implicitHeight: Appearance.island.control.chip
    radius: Appearance.island.control.cardRadius
    color: Colors.surfaceContainerHigh

    StyledRect {
        width: root.width * Math.max(0, Math.min(1, root.value))
        height: parent.height
        color: Colors.primaryContainer

        Behavior on width {
            Anim {}
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => {
            if (mouse.button === Qt.RightButton)
                root.opened();
            else
                root.moved(root.valueAt(mouse.x));
        }
        onPositionChanged: mouse => {
            if (pressedButtons & Qt.LeftButton)
                root.moved(root.valueAt(mouse.x));
        }
    }

    WheelArea {
        anchors.fill: parent
        onStepped: step => root.moved(Math.max(0, Math.min(1, root.value - step * root.step)))
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.island.control.cardSidePadding
        anchors.rightMargin: Appearance.island.control.cardSidePadding
        spacing: Appearance.spacing.normal

        MaterialIcon {
            text: root.icon
            color: Colors.primaryContainerFg

            // Exclusive grab on press, so the chip's MouseArea doesn't also set the value.
            TapHandler {
                margin: Appearance.spacing.small
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: root.iconClicked()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.label
                elide: Text.ElideRight
                color: Colors.surfaceVariantFg
                font.pixelSize: Appearance.font.size.small
            }

            StyledText {
                Layout.fillWidth: true
                text: root.status
                elide: Text.ElideRight
                font.weight: Font.DemiBold
            }
        }
    }
}
