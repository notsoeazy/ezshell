import QtQuick
import qs.config
import qs.components

// Push and pop navigation. The stack takes the size of its top page and
// morphs between pages, sliding forward on push and back on pop. Pages are
// created when shown and destroyed when left.
Item {
    id: root

    // The page at the bottom of the stack.
    required property Component initial
    property list<Component> pages: [initial]
    readonly property int depth: pages.length
    readonly property Item currentPage: morph.item

    function push(page: Component): void {
        morph.direction = 1;
        pages = [...pages, page];
    }

    function pop(): void {
        if (depth <= 1)
            return;

        morph.direction = -1;
        pages = pages.slice(0, -1);
    }

    function reset(): void {
        morph.direction = -1;
        pages = [initial];
    }

    implicitWidth: morph.implicitWidth
    implicitHeight: morph.implicitHeight

    Keys.onEscapePressed: event => {
        if (depth > 1)
            pop();
        else
            event.accepted = false;
    }

    Morph {
        id: morph

        anchors.fill: parent
        travel: Tokens.spacing.xxxl
        content: root.pages[root.pages.length - 1]
    }
}
