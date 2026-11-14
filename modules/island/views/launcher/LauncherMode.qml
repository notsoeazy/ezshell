import QtQuick

// Base of a launcher mode: what the launcher searches, and what happens when
// a result is chosen. A result is an object with `title`, and optionally
// `subtitle`, `icon` (an icon name), `image` (a picture path) or `glyph` (a
// character), plus whatever the mode needs to act on it.
QtObject {
    required property string name
    // What the search must start with to pick this mode; empty for the
    // default mode.
    property string prefix
    property string placeholder
    property string icon: "search"
    // Shown when the search finds nothing.
    property string emptyText: "No results"

    // Called when the mode becomes the current one.
    function prepare(): void {
    }

    function results(query: string): list<var> {
        return [];
    }

    function activate(result: var): void {
    }
}
