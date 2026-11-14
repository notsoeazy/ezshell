pragma Singleton

import QtQuick
import Quickshell

// The current time. Ticks once a minute, which is all the clock needs.
Singleton {
    readonly property date now: clock.date

    // A length of time as "1:42", or "1:02:03" from an hour up.
    function duration(seconds: real): string {
        const total = Math.max(0, Math.floor(seconds));
        const hours = Math.floor(total / 3600);
        const minutes = Math.floor(total % 3600 / 60);
        const rest = `${total % 60}`.padStart(2, "0");
        return hours > 0 ? `${hours}:${`${minutes}`.padStart(2, "0")}:${rest}` : `${minutes}:${rest}`;
    }

    function format(pattern: string): string {
        return Qt.formatDateTime(clock.date, pattern);
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }
}
