import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.modules.island

// The one place that decides which events make the island show `default` for a moment.
Scope {
    id: root

    // Services report their first values just after startup
    property bool delay

    function fire(kind: string): void {
        if (delay && Config.island.pulseOn.includes(kind))
            IslandState.pulse();
    }

    Timer {
        running: true
        interval: 2000
        onTriggered: root.delay = true
    }

    Connections {
        function onActiveWorkspaceChanged(): void {
            root.fire("workspace");
        }

        function onActiveSpecialChanged(): void {
            root.fire("special");
        }

        target: Hypr
    }

    Connections {
        function onVolumeChanged(): void {
            root.fire("volume");
        }

        function onMutedChanged(): void {
            root.fire("volume");
        }

        function onMicMutedChanged(): void {
            root.fire("mic");
        }

        target: Audio
    }

    Connections {
        function onConnectedChanged(): void {
            root.fire("network");
        }

        target: Network
    }

    Connections {
        function onPluggedInChanged(): void {
            root.fire("battery");
        }

        function onLowChanged(): void {
            root.fire("battery");
        }

        target: Battery
    }

    Connections {
        function onTitleChanged(): void {
            root.fire("media");
        }

        target: Media
    }

    Connections {
        function onCountChanged(): void {
            root.fire("notification");
        }

        target: Notifications
    }
}
