pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

Singleton {
    id: root

    readonly property ObjectModel items: SystemTray.items

    function activate(item: SystemTrayItem): void {
        item.activate();
    }

    function secondaryActivate(item: SystemTrayItem): void {
        item.secondaryActivate();
    }

    // x and y are relative to window.
    function openMenu(item: SystemTrayItem, window: QtObject, x: int, y: int): void {
        if (item.hasMenu)
            item.display(window, x, y);
    }

    function ids(): string {
        return SystemTray.items.values.map(i => i.id).join("\n");
    }

    IpcHandler {
        function list(): string {
            return root.ids();
        }

        target: "tray"
    }
}
