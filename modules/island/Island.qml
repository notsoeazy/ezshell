import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.modules.background
import qs.modules.island
import qs.modules.island.views

// The island: one window on one monitor, plus the strip it reserves.
Scope {
    id: root

    Binding {
        target: IslandState
        property: "knownViews"
        value: Registry.names
    }

    Pulses {}

    // A panel or sheet already shows what the OSD would.
    Binding {
        target: Osd
        property: "blocked"
        value: !IslandState.inState
    }

    Binding {
        target: Notifications
        property: "held"
        value: IslandState.pointerInside && IslandState.current === "banner"
    }

    Binding {
        target: Osd
        property: "held"
        value: IslandState.pointerInside && IslandState.current === "osd"
    }

    // The strip under the island: its height plus the configured gap.
    ExclusiveZone {
        screen: IslandState.screen
        edge: "top"
        size: Tokens.island.height + Config.island.reserveGap
    }

    IslandWindow {
        screen: IslandState.screen
    }
}
