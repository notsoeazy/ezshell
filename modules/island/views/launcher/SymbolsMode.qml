import QtQuick
import qs.config
import qs.services

// Emoji, symbols and Nerd Font glyphs by name: choose one to copy it.
LauncherMode {
    name: "symbols"
    prefix: Config.launcher.symbolsPrefix
    placeholder: "Search emoji, symbols and Nerd Font glyphs"
    icon: "emoji_symbols"
    emptyText: "Nothing found"

    function results(query: string): list<var> {
        return Glyphs.search(query, Config.launcher.maxResults);
    }

    function activate(result: var): void {
        Clipboard.copyText(result.glyph);
    }
}
