import Quickshell.Widgets
import qs.config

// Base of every island view. A view is its content plus padding. Its size is its content's size
WrapperItem {
    property bool wantsKeyboard
    property bool dismissible
    property bool holdOnHover
    property bool showOverFullscreen

    margin: Tokens.island.paddingY
    leftMargin: Tokens.island.paddingX
    rightMargin: Tokens.island.paddingX
}
