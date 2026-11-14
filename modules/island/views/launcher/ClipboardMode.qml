import qs.config
import qs.services
import qs.utils

// Clipboard history: choose an entry to copy it again.
LauncherMode {
    name: "clipboard"
    prefix: Config.launcher.clipboardPrefix
    placeholder: "Search clipboard history"
    icon: "content_paste"
    emptyText: "Clipboard history is empty"

    function prepare(): void {
        Clipboard.refresh();
    }

    function results(query: string): list<var> {
        return Clipboard.entries.filter(entry => Fuzzy.score(query, entry.text) > 0).map(entry => ({
                    // One line, and something to show for a blank entry.
                    title: entry.text.replace(/\s+/g, " ").trim() || "(blank)",
                    icon: entry.image ? "image" : "content_paste",
                    id: entry.id
                }));
    }

    function activate(result: var): void {
        Clipboard.copy(result.id);
    }
}
