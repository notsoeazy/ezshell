import QtQuick
import QtQuick.Effects
import Quickshell
import qs.config
import qs.theme
import qs.components
import qs.services
import qs.modules.island

// The distribution's logo, in the label colour. Click it for the launcher.
Item {
    id: root

    readonly property string name: Config.island.logo.length > 0 ? Config.island.logo : Distro.logo
    // A file path as given, else a name looked up in the icon theme.
    readonly property string source: {
        if (name.length === 0)
            return "";
        if (name.startsWith("/") || name.startsWith("~"))
            return `file://${name.replace(/^~/, Quickshell.env("HOME"))}`;
        return Quickshell.iconPath(name, true);
    }

    visible: Config.island.showLogo && source.length > 0
    implicitWidth: visible ? Tokens.icon.sm : 0
    implicitHeight: visible ? Tokens.icon.sm : 0

    Image {
        id: image

        anchors.fill: parent
        source: root.source
        sourceSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: image
        source: image
        colorization: 1
        colorizationColor: Theme.color.label
    }

    Pressable {
        radius: Tokens.radius.sm
        onActivated: IslandState.toggle("launcher")
    }
}
