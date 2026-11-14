import qs.config
import qs.components
import qs.services

// The time. One component for every clock the shell shows, so that a clock
// can later travel between places (island to lock screen) by animating `fontSize`.
Label {
    text: Time.format(Config.island.clockFormat)
    emphasized: true
    tabular: true
}
