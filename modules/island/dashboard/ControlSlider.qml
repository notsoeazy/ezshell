import QtQuick
import QtQuick.Layouts
import qs.components
import qs.themes

// A Control-tab slider card (docs/ISLAND-R1.md): a label row with a chevron that opens the detail
// section, and a 20 px track whose fill carries the icon. Dragging, clicking and scrolling report `moved`;
// the owner writes the value back. A click on the icon reports `iconClicked` (Sound: mute).
StyledRect {
    id: root

    property string label: ""
    property string detail: ""
    property string icon: ""
    property real value: 0
    // Change per wheel notch.
    property real step: 0.05

    signal moved(real value)
    signal iconClicked
    signal opened

    function valueAt(x: real): real {
        return Math.max(0, Math.min(1, x / track.width));
    }

    implicitHeight: column.implicitHeight + 2 * Appearance.island.control.cardPadding
    radius: Appearance.island.control.cardRadius
    color: Colors.surfaceContainerHigh

    ColumnLayout {
        id: column

        anchors.fill: parent
        anchors.topMargin: Appearance.island.control.cardPadding
        anchors.bottomMargin: Appearance.island.control.cardPadding
        anchors.leftMargin: Appearance.island.control.cardSidePadding
        anchors.rightMargin: Appearance.island.control.cardSidePadding
        spacing: Appearance.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            StyledText {
                text: root.label
                font.pixelSize: Appearance.island.control.title
                font.weight: Font.Medium
            }

            StyledText {
                Layout.fillWidth: true
                text: root.detail
                elide: Text.ElideRight
                color: Colors.surfaceVariantFg
                font.pixelSize: Appearance.font.size.small
            }

            MaterialIcon {
                text: "chevron_right"
                color: Colors.surfaceVariantFg

                TapHandler {
                    margin: Appearance.spacing.small
                    onTapped: root.opened()
                }
            }
        }

        StyledRect {
            id: track

            Layout.fillWidth: true
            implicitHeight: Appearance.island.control.track
            radius: height / 2
            color: Colors.surfaceContainerHighest

            // At least as wide as the icon, so the icon always sits on the fill.
            StyledRect {
                width: Math.max(track.height, track.width * Math.max(0, Math.min(1, root.value)))
                height: parent.height
                radius: parent.radius
                color: Colors.primary

                Behavior on width {
                    Anim {}
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPressed: mouse => root.moved(root.valueAt(mouse.x))
                onPositionChanged: mouse => root.moved(root.valueAt(mouse.x))
            }

            WheelArea {
                anchors.fill: parent
                onStepped: step => root.moved(Math.max(0, Math.min(1, root.value - step * root.step)))
            }

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                x: (track.height - width) / 2
                text: root.icon
                size: Appearance.font.size.normal
                color: Colors.primaryFg

                // Exclusive grab on press, so the track's MouseArea doesn't also set the value.
                TapHandler {
                    margin: Appearance.spacing.small
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: root.iconClicked()
                }
            }
        }
    }
}
