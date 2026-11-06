pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.themes

// One list row: an icon box (a picture from the provider, an app icon or a Material Symbol), the title
// and subtitle, and the Enter hint on the selected row.
StyledRect {
    id: root

    required property var modelData
    required property int index
    property bool current: false
    // file:// URL of a picture for the icon box, "" for none (Provider.preview).
    property string picture: ""

    signal hovered
    signal clicked(int modifiers)

    implicitHeight: Appearance.island.launcher.row
    radius: Appearance.rounding.normal
    color: root.current ? Colors.surfaceContainerHigh : Colors.transparent

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered()
        onClicked: mouse => root.clicked(mouse.modifiers)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.island.launcher.padding
        anchors.rightMargin: Appearance.island.launcher.padding
        spacing: Appearance.island.launcher.padding

        ClippingRectangle {
            implicitWidth: Appearance.island.launcher.icon
            implicitHeight: Appearance.island.launcher.icon
            radius: Appearance.island.launcher.iconRadius
            color: Colors.surfaceContainerHighest

            Image {
                id: thumb

                anchors.fill: parent
                visible: root.picture !== ""
                source: root.picture
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: Appearance.island.launcher.icon
                sourceSize.height: Appearance.island.launcher.icon
            }

            IconImage {
                anchors.fill: parent
                anchors.margins: Appearance.spacing.small
                visible: root.modelData.image !== undefined
                source: visible ? Quickshell.iconPath(root.modelData.image, "application-x-executable") : ""
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: root.modelData.icon !== undefined && !thumb.visible
                text: root.modelData.icon ?? ""
                color: Colors.surfaceFg
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.modelData.title
                elide: Text.ElideRight
                font.weight: Font.Medium
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.modelData.subtitle ?? ""
                elide: Text.ElideRight
                color: Colors.surfaceVariantFg
                font.pixelSize: Appearance.font.size.small
            }
        }

        StyledText {
            visible: root.current
            text: "Enter"
            color: Colors.surfaceVariantFg
            font.pixelSize: Appearance.font.size.small
            font.weight: Font.Medium
        }
    }
}
