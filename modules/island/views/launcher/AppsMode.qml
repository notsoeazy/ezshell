import qs.services

// Applications: the default mode.
LauncherMode {
    name: "apps"
    placeholder: "Search apps"
    emptyText: "No apps found"

    function results(query: string): list<var> {
        return Apps.search(query).map(app => ({
                    title: app.name,
                    subtitle: app.genericName || app.comment,
                    image: Apps.icon(app),
                    icon: "apps",
                    app: app
                }));
    }

    function activate(result: var): void {
        Apps.launch(result.app);
    }
}
