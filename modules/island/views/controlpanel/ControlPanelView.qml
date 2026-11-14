import QtQuick
import qs.config
import qs.components
import qs.modules.island
import qs.modules.island.views.controlpanel

// The control panel: a root page of toggles and sliders, and detail pages
// that slide in over it. Which page shows is IslandState.panelPage.
View {
    dismissible: true
    // Text fields on its pages need the keyboard.
    wantsKeyboard: true
    margin: Tokens.island.panelPadding

    Morph {
        // Forward to a detail page, back to the root.
        direction: IslandState.panelPage.length > 0 ? 1 : -1
        travel: Tokens.spacing.xxxl
        // The island animates the size; this only swaps the pages.
        animateSize: false
        alignment: Qt.AlignLeft | Qt.AlignTop
        content: Pages.component(IslandState.panelPage)
    }
}
