import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// The focused app: its icon and name, or "Desktop" when nothing is focused.
// The name comes from the app's desktop entry, not from the window's title
// (see `Hypr.activeAppName`). If the icon cannot be found or loaded, a
// generic one stands in. It is laid out like `NotificationSummary`; it will
// open the window's details once there is a view for them, until then it
// does nothing.
HeaderChip {
    id: root

    readonly property string iconPath: Hypr.activeAppIcon.length > 0 ? Quickshell.iconPath(Hypr.activeAppIcon, true) : ""
    readonly property bool hasIcon: iconPath.length > 0 && image.status === Image.Ready

    interactive: false

    IconImage {
        id: image

        visible: root.hasIcon
        implicitSize: Tokens.icon.sm
        source: root.iconPath
    }

    Icon {
        visible: !root.hasIcon
        name: Hypr.hasActiveWindow ? "web_asset" : "desktop_windows"
        size: Tokens.icon.sm
    }

    Label {
        text: Hypr.activeAppName
        fontSize: Tokens.fontSize.md
    }
}
