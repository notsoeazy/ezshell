import QtQuick
import qs.config
import qs.theme

// The interaction layer every clickable component is built on. Fills its
// parent, draws the hover and pressed highlight and the keyboard focus ring,
// and reports one `activated` signal for click, Space and Return, plus
// `secondaryActivated` for a right click.
MouseArea {
    id: root

    property bool disabled
    // Whether it shows hover, press and focus. Off for something that is
    // clicked but should not look like a button; it still reports `activated`.
    property bool feedback: true
    // Match the parent's corner radius so the highlight follows its shape.
    property real radius
    property color tint: Theme.color.label
    readonly property bool hovered: containsMouse && !disabled
    readonly property bool down: pressed && !disabled

    signal activated
    // Right click: for a secondary action such as opening more options.
    signal secondaryActivated

    anchors.fill: parent
    enabled: !disabled
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    activeFocusOnTab: !disabled && feedback

    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: event => {
        if (event.button === Qt.RightButton)
            secondaryActivated();
        else
            activated();
    }
    Keys.onSpacePressed: activated()
    Keys.onReturnPressed: activated()
    Keys.onEnterPressed: activated()

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.tint
        opacity: !root.feedback ? 0 : root.down ? Tokens.state.pressed : root.hovered ? Tokens.state.hover : 0

        Behavior on opacity {
            Anim {
                style: Tokens.motion.effectsFast
            }
        }
    }

    // Focus only arrives by keyboard (clicking does not focus), so the ring
    // never shows for pointer users.
    Rectangle {
        anchors.fill: parent
        anchors.margins: -Tokens.state.focusRing * 2
        radius: root.radius + Tokens.state.focusRing * 2
        color: "transparent"
        border.color: Theme.accent
        border.width: Tokens.state.focusRing
        opacity: root.activeFocus ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                style: Tokens.motion.effectsFast
            }
        }
    }
}
