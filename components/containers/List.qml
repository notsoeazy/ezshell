pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.components
import qs.components.containers

// HIG list, inset grouped style: a rounded group of rows from a model, with a
// highlight that glides to the current row. Keyboard focus usually stays in a
// search field, so the owner calls `moveBy` and `activateCurrent`.
ClippingRectangle {
    id: root

    property alias model: view.model
    property alias delegate: view.delegate
    property alias currentIndex: view.currentIndex
    readonly property alias count: view.count
    // The list grows with its rows up to this height, then scrolls.
    property real maxHeight: Infinity
    // Turn off for a plain list of rows with no current-row highlight.
    property bool selectable: true
    // Space between the list's edge and its rows, which the highlight keeps to
    // so that it is a rounded pill inside the list and not a band to its edge.
    property real inset: Tokens.spacing.xs
    // The current row's highlight, and how round it is.
    property color highlightColor: Theme.color.fill
    property real highlightRadius: Tokens.radius.sm
    property alias spacing: view.spacing
    // Drawn inside the current-row highlight, so that it moves with it: a hint
    // at the end of the current row, say. It fills the highlight.
    property Component highlightContent

    signal activated(index: int)

    function moveBy(delta: int): void {
        if (count > 0)
            view.currentIndex = Math.max(0, Math.min(count - 1, view.currentIndex + delta));
    }

    function activateCurrent(): void {
        if (view.currentIndex >= 0 && view.currentIndex < count)
            activated(view.currentIndex);
    }

    implicitWidth: Tokens.spacing.xxxl * 10
    implicitHeight: Math.min(view.contentHeight + inset * 2, maxHeight)
    radius: Tokens.radius.md
    color: Theme.color.surfaceRaised

    Keys.onUpPressed: moveBy(-1)
    Keys.onDownPressed: moveBy(1)
    Keys.onReturnPressed: activateCurrent()
    Keys.onEnterPressed: activateCurrent()

    Behavior on color {
        ColorAnim {}
    }

    ListView {
        id: view

        anchors.fill: parent
        boundsBehavior: Flickable.StopAtBounds
        highlightFollowsCurrentItem: false
        topMargin: root.inset
        bottomMargin: root.inset

        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

        highlight: Rectangle {
            x: root.inset
            y: view.currentItem?.y ?? 0
            width: view.width - root.inset * 2
            height: view.currentItem?.height ?? 0
            radius: root.highlightRadius
            color: root.highlightColor
            visible: root.selectable && view.currentItem !== null

            Behavior on y {
                Anim {
                    style: Tokens.motion.effectsFast
                }
            }

            Loader {
                anchors.fill: parent
                sourceComponent: root.highlightContent
            }
        }

        ScrollBar {
            parent: view
            flickable: view
        }
    }
}
