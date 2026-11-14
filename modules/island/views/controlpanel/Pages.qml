pragma Singleton

import QtQuick
import Quickshell
import qs.modules.island.views.controlpanel

// The control panel's pages, by name; "" is the root page. Adding a page
// means adding it here and nowhere else.
Singleton {
    readonly property var components: ({
            "": root,
            "wifi": wifi,
            "bluetooth": bluetooth,
            "audio": audio,
            "nightlight": nightLight
        })
    readonly property list<string> names: Object.keys(components)

    function has(name: string): bool {
        return components[name] !== undefined;
    }

    function component(name: string): Component {
        return components[name] ?? root;
    }

    Component {
        id: root

        RootPage {}
    }

    Component {
        id: wifi

        WifiPage {}
    }

    Component {
        id: bluetooth

        BluetoothPage {}
    }

    Component {
        id: audio

        AudioPage {}
    }

    Component {
        id: nightLight

        NightLightPage {}
    }
}
