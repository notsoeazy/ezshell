import qs.config
import qs.utils
import qs.modules.island.views.launcher

// Things the shell can do, by name.
LauncherMode {
    name: "actions"
    prefix: Config.launcher.actionsPrefix
    placeholder: "Run an action"
    icon: "bolt"
    emptyText: "No actions found"

    function results(query: string): list<var> {
        return Actions.list.map(action => ({
                    action: action,
                    score: Fuzzy.best(query, [action.title, action.keywords ?? ""], [1, 0.6])
                })).filter(match => match.score > 0).sort((a, b) => b.score - a.score).map(match => match.action);
    }

    function activate(result: var): void {
        result.run();
    }
}
