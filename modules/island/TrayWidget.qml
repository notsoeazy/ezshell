pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.themes

RowLayout {
    id: root

    spacing: Appearance.spacing.normal

    Repeater {
        model: Tray.items

        IconImage {
            id: icon

            required property var modelData

            function click(button: int): void {
                const pos = icon.mapToItem(null, 0, icon.height);
                if (button === Qt.LeftButton && !icon.modelData.onlyMenu)
                    Tray.activate(icon.modelData);
                else if (button === Qt.MiddleButton)
                    Tray.secondaryActivate(icon.modelData);
                else
                    Tray.openMenu(icon.modelData, QsWindow.window, pos.x, pos.y);
            }

            source: modelData.icon
            implicitSize: Appearance.island.trayIcon

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                onClicked: mouse => icon.click(mouse.button)
            }
        }
    }
}
