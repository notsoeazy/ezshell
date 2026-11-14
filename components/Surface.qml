import QtQuick
import qs.config
import qs.theme

// A rounded container filled with a colour token. Colour changes (including a
// switch between light and dark) crossfade.
Rectangle {
    color: Theme.color.surfaceRaised
    radius: Tokens.radius.md

    Behavior on color {
        ColorAnim {}
    }
}
