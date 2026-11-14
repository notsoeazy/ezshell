import Quickshell.Wayland
import qs.config
import qs.theme
import qs.modules.island
import qs.modules.lock

// The lock screen on one monitor.
WlSessionLockSurface {
    id: root

    color: Theme.dark.surface

    LockContent {
        anchors.fill: parent
        // On the island's monitor the clock grows out of the island.
        travels: Config.island.enabled && root.screen === IslandState.screen
    }
}
