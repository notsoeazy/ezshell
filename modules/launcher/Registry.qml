import QtQuick

// The launcher's providers. Adding one is a file in this folder plus one line in `providers`.
QtObject {
    id: root

    // Everything typed in the launcher, prefix included.
    property string text: ""
    readonly property list<Provider> providers: [
        AppsProvider {},
        ActionsProvider {}
    ]
    readonly property Provider fallback: root.providers.find(p => p.prefix === "") ?? null
    readonly property Provider active: root.pick(root.text)
    // Prefixed providers, for the empty launcher's hints.
    readonly property list<Provider> prefixed: root.providers.filter(p => p.prefix !== "")
    readonly property var items: root.active?.items ?? []

    // A typed prefix picks its provider; anything else goes to the default one.
    function pick(text: string): Provider {
        return root.providers.find(p => p.prefix !== "" && text.startsWith(p.prefix)) ?? root.fallback;
    }

    // Only the active provider gets the query, so the others compute nothing.
    function sync(): void {
        for (const provider of root.providers) {
            provider.current = provider === root.active;
            provider.query = provider.current ? root.text.slice(provider.prefix.length) : "";
        }
    }

    function activate(item: var, modifier: int): void {
        if (item)
            root.active?.activated(item, modifier);
    }

    onTextChanged: root.sync()
    onActiveChanged: root.sync()
    Component.onCompleted: root.sync()
}
