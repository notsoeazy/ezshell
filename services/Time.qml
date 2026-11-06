pragma Singleton
import QtQuick
import Quickshell
import qs.config

Singleton {
    id: root

    readonly property date date: clock.date
    // Qt format string for the time, from the user's 12/24-hour and seconds settings.
    readonly property string timeFormat: root.buildFormat(Config.bar.use24Hour, Config.bar.showSeconds)

    function buildFormat(use24Hour: bool, showSeconds: bool): string {
        const hours = use24Hour ? "HH:mm" : "h:mm";
        return hours + (showSeconds ? ":ss" : "") + (use24Hour ? "" : " AP");
    }

    SystemClock {
        id: clock

        precision: Config.bar.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }
}
