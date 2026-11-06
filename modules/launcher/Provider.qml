import QtQuick

// One launcher provider: a prefix, the rows it offers for the text after it, and what Enter does.
// Each provider is one file with this as its root; Registry.qml lists them.
QtObject {
    id: root

    // Typed first to pick this provider; "" is the default (apps).
    property string prefix: ""
    // Shown in the empty launcher's prefix hints.
    property string name: ""
    property string icon: ""
    // Shown when nothing matches.
    property string emptyText: "No matches"
    // The launcher's footer while this provider is active.
    property string hints: "↑↓ navigate    ⏎ open    esc close"
    // Whether Delete removes the selected row (removed() is then emitted).
    property bool removable: false
    // Set by the Registry: whether this provider is picked, and the text after its prefix ("" otherwise).
    property bool current: false
    property string query: ""
    // Rows, plain objects: key (unique), title, subtitle, and icon (a Material Symbols name) or image
    // (an icon theme name), plus anything activated() needs.
    property var items: []

    // Enter or a click on a row; modifier holds the keyboard modifiers (Alt for alternate actions).
    signal activated(var item, int modifier)
    signal removed(var item)

    // A picture file for a row (clipboard images), "" for none. Called from each visible row's binding,
    // so a provider can prepare previews only for the rows on screen. Providers with pictures override it.
    function preview(item: var): string {
        return "";
    }
}
