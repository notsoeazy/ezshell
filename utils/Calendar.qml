pragma Singleton

import Quickshell

// Pure month-grid helpers. Weeks start on Sunday, as in frame 14.
Singleton {
    readonly property list<string> weekdays: ["S", "M", "T", "W", "T", "F", "S"]

    // The month `offset` months from `today`, as its first day.
    function monthStart(today: date, offset: int): date {
        return new Date(today.getFullYear(), today.getMonth() + offset, 1);
    }

    // 42 cells (6 weeks) for the month starting at `first`: { day, inMonth, today }.
    function cells(first: date, today: date): var {
        const start = new Date(first.getFullYear(), first.getMonth(), 1 - first.getDay());
        return Array.from({
            length: 42
        }, (_, i) => {
            const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
            return {
                day: d.getDate(),
                inMonth: d.getMonth() === first.getMonth(),
                today: d.toDateString() === today.toDateString()
            };
        });
    }
}
