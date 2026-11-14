pragma Singleton

import QtQuick
import Quickshell
import qs.modules.island.views.launcher

// The launcher's modes. The start of the search picks one: a mode's prefix,
// or the apps mode if none matches. Adding a mode means adding it here and
// nowhere else.
Singleton {
    id: root

    readonly property LauncherMode apps: AppsMode {}
    readonly property list<LauncherMode> prefixed: [
        ActionsMode {},
        ClipboardMode {},
        SymbolsMode {}
    ]

    function modeFor(text: string): LauncherMode {
        return prefixed.find(mode => mode.prefix.length > 0 && text.startsWith(mode.prefix)) ?? apps;
    }

    // The part of the search after the mode's prefix.
    function queryFor(text: string): string {
        return text.slice(modeFor(text).prefix.length).trim();
    }
}
