pragma Singleton

import Quickshell

// Whether the screen is being kept from idling. Not remembered between runs.
// The inhibitor itself needs a window, so it lives in the island's window and
// follows this.
Singleton {
    property bool enabled

    function toggle(): void {
        enabled = !enabled;
    }
}
