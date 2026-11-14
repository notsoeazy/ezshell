// Qt's default wheel scrolling coasts for a long time; this makes it stop promptly.
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
// Qt's Wayland text-input integration logs "Trying to disable ... but 0x0 is
// focused" whenever the island's keyboard focus moves (a click to open the control
// panel, a view change), because the island has no text field focused at that
// moment. The compose input context takes keys straight from the keyboard and
// leaves that protocol out. The cost: no input-method editors (fcitx, ibus).
//@ pragma DefaultEnv QT_IM_MODULE=compose

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.modules.background
import qs.modules.capture
import qs.modules.island
import qs.modules.lock
import qs.modules.settings

ShellRoot {
    id: root

    // Vendored in assets/fonts; see the README there.
    readonly property list<string> fonts: ["Geist/Geist-Variable.ttf", "Geist/GeistMono-Variable.ttf", "NerdSymbols/SymbolsNerdFont-Regular.ttf"]

    settings.watchFiles: true

    Background {}
    Border {}
    Settings {}
    LockScreen {}
    CapturePicker {}
    Ipc {}
    Shortcuts {}
    Idle {}
    Theming {}

    LazyLoader {
        active: Config.island.enabled

        Island {}
    }

    Instantiator {
        model: root.fonts

        FontLoader {
            required property string modelData

            source: Quickshell.shellPath(`assets/fonts/${modelData}`)
        }
    }
}
